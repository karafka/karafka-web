# frozen_string_literal: true

# Simple validator that extracts all the links rendered after each page and visits them to make
# sure, that we do not have any dead links.
class LinksValidator
  include Singleton

  # 200 - ok
  # 302, 304 - redirects
  # 402 - paid pro feature
  ALLOWED_RESPONSES = [200, 302, 304, 402].freeze

  # Cases that are hardcoded or come from fixtures that are always 404 or are expected to fail
  # in other ways
  EXCEPTIONS = [
    %r{explorer/topics/\w+/\d+},
    %r{explorer/topics/it-[a-f0-9-]+},
    %r{consumers/[a-z0-9-]+:[a-z0-9]+(:[a-z0-9]+)?/subscriptions},
    "/explorer/topics/test3",
    # Fixture-based topic name (errors/consumers reports) that does not exist in the test
    # cluster, so the bare topic link (no partition/offset segment) always 404s
    "/explorer/topics/default",
    %r{/consumers/[a-f0-9-]+/subscriptions}
  ].freeze

  # Controllers on which we do not want to run checks or want to run only some checks.
  # Some controllers like the status one set explicitly system into incorrect states that can
  # cause other links not to work correctly. This is why we should not check links on their
  # usage
  EXCLUDED_CONTROLLERS = {
    # Covers both oss and pro. On status since there are so many invalid we exclude all
    "StatusController" => [/.*/],
    # Also deals with invalid state that affects dashboard
    "RoutingController" => [%r{/dashboard}, %r{/jobs}, %r{/health}],
    # The distribution/replication specs stub `ClusterInfo.fetch` with fabricated multi-broker
    # metadata; crawling `/topics` renders it against that stubbed state plus real Kafka calls on
    # a fresh cluster, which intermittently 500s. `/topics` is validated by its own controller
    # specs, so we skip it (and `/explorer`) when crawling from the cluster views.
    "ClusterController" => [%r{/explorer}, %r{\A/topics}],
    # Replication rows render broker-id badges that link to per-broker detail pages. In specs
    # the topic metadata is stubbed with hypothetical multi-broker replica sets, so brokers
    # other than node 1 do not exist in the single-node test cluster. We still validate the
    # broker 1 detail link (which exists on CI) and only skip the fabricated higher broker ids.
    "ReplicationsController" => [%r{/cluster/(?!1\b)\d+}]
  }.freeze

  # Descriptions that indicate some features disabled
  # We do not track links on those as they may return 403 and other unexpected statuses
  EXCLUDED_DESCRIPTIONS = [
    "is disabled",
    "is not enabled"
  ].freeze

  # There is no point in visiting same urls for different uuids (like topic views). We use those
  # regexps as a baseline to build visited keys so we know that we visited one and worked
  KEY_TRANSFORMERS = [
    /it-[0-9a-f]{6}-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/,
    /[a-z0-9]+:\d+:\d+/
  ].freeze

  # A crawled link can briefly return a 5xx for reasons unrelated to the page under test - most
  # notably the Kafka coordinator still loading right after the cluster starts, which makes a
  # metadata-backed page (e.g. `/topics`) 500 for a moment. We retry such links a few times before
  # treating the failure as real, so these transient blips do not redden unrelated specs.
  MAX_RETRIES = 3
  RETRY_BACKOFF = 0.25

  private_constant(
    :ALLOWED_RESPONSES, :EXCLUDED_CONTROLLERS, :EXCLUDED_DESCRIPTIONS, :MAX_RETRIES, :RETRY_BACKOFF
  )

  attr_writer :context, :description

  # Initialize the set of visited links
  def initialize
    @visited_links = Set.new
  end

  # Processes a response by extracting and validating all links
  # @param response [Rack::MockResponse] request response
  def validate_all!(response)
    return unless response.content_type.include?("text/html")

    html = Nokogiri::HTML(response.body)
    links = extract_links(html)

    links.each do |link|
      validate!(link)
    end
  end

  private

  # Extract all internal links from HTML
  #
  # @param html [Nokogiri::HTML4::Document] nokogiri document
  # @return [Array<String>] list of links potentially to visit
  def extract_links(html)
    # Get all anchor tags with href attributes
    links = html.css("a[href]").map { |a| a["href"] }

    # Filter to only include internal links (not external or anchors)
    links.delete_if do |link|
      next true if link.start_with?("#", "http://", "https://", "mailto:", "tel:")
      next true if link.empty?
      next true if EXCLUDED_DESCRIPTIONS.any? { |excluded| @description.to_s.include?(excluded) }

      false
    end

    links.delete_if do |link|
      EXCLUDED_CONTROLLERS.any? do |klass, matches|
        @context.described_class.to_s.include?(klass) && matches.any? do |match|
          link =~ match
        end
      end
    end

    links
  end

  # Validates a single link by visiting the page under the link and checking the response status
  #
  # @param link [String]
  def validate!(link)
    # Skip if one of exceptions
    return if EXCEPTIONS.any? do |exception|
      if exception.is_a?(String)
        link == exception
      else
        link.match?(exception)
      end
    end

    link_key = visit_key(link)

    # Skip if we've already visited this link
    return if @visited_links.include?(link_key)

    # Add to visited set to avoid checking again
    @visited_links.add(link_key)

    # First visit. Some specs inject invalid data on purpose, corrupting the views we reach out
    # to, so a raised error on the initial request means we skip the link entirely.
    begin
      @context.get(link)
    rescue
      return
    end

    resp = @context.last_response
    status = resp.status

    # A metadata-backed page can transiently 5xx (e.g. Kafka coordinator load right after the
    # cluster starts). We retry a 5xx a few times. A genuine error still 5xxs after the retries and
    # is reported - once we have seen a 5xx we never skip the link, even if a retry raises.
    attempts = 0
    while status >= 500 && attempts < MAX_RETRIES
      attempts += 1
      sleep(RETRY_BACKOFF)

      begin
        @context.get(link)
      rescue
        break
      end

      resp = @context.last_response
      status = resp.status
    end

    return if ALLOWED_RESPONSES.include?(status)

    body_snippet = resp.body.to_s[0, 500].gsub(/\s+/, " ").strip
    assert_msg = "Link '#{link}' returned #{status} status.\nBody: #{body_snippet}"
    @context.assert_includes(ALLOWED_RESPONSES, status, assert_msg)
  end

  # Builds a visit key so we track similar links and do not visit similar stuff twice
  # @param link [String]
  # @return [String]
  def visit_key(link)
    final_key = link.dup

    KEY_TRANSFORMERS.each do |transformer|
      final_key = final_key.gsub(transformer, "KEY")
    end

    final_key
  end
end
