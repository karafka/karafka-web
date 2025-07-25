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
    %r{explorer/topics/it-[a-f0-9-]+/\d+},
    %r{consumers/[a-z0-9]+:[a-f0-9]+:[a-f0-9]+/subscriptions},
    # github runners process names
    %r{consumers/fv-[a-z0-9:-]+/subscriptions},
    '/explorer/topics/test3',
    %r{/consumers/[a-f0-9-]+/subscriptions}
  ].freeze

  # Controllers on which we do not want to run checks or want to run only some checks.
  # Some controllers like the status one set explicitly system into incorrect states that can
  # cause other links not to work correctly. This is why we should not check links on their
  # usage
  EXCLUDED_CONTROLLERS = {
    # Covers both oss and pro. On status since there are so many invalid we exclude all
    'StatusController' => [/.*/],
    # Also deals with invalid state that affects dashboard
    'RoutingController' => [%r{/dashboard}, %r{/jobs}, %r{/health}],
    'ClusterController' => [%r{/explorer}]
  }.freeze

  # Descriptions that indicate some features disabled
  # We do not track links on those as they may return 403 and other unexpected statuses
  EXCLUDED_DESCRIPTIONS = [
    'is disabled',
    'is not enabled'
  ].freeze

  # There is no point in visiting same urls for different uuids (like topic views). We use those
  # regexps as a baseline to build visited keys so we know that we visited one and worked
  KEY_TRANSFORMERS = [
    /it-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/,
    /[a-z0-9]+:\d+:\d+/
  ].freeze

  private_constant :ALLOWED_RESPONSES, :EXCLUDED_CONTROLLERS, :EXCLUDED_DESCRIPTIONS

  attr_writer :context

  # Initialize the set of visited links
  def initialize
    @visited_links = Set.new
  end

  # Processes a response by extracting and validating all links
  # @param response [Rack::MockResponse] request response
  def validate_all!(response)
    return unless response.content_type.include?('text/html')

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
    links = html.css('a[href]').map { |a| a['href'] }
    full_description = RSpec.current_example.metadata[:full_description]

    # Filter to only include internal links (not external or anchors)
    links.delete_if do |link|
      next true if link.start_with?('#', 'http://', 'https://', 'mailto:', 'tel:')
      next true if link.empty?
      next true if EXCLUDED_DESCRIPTIONS.any? { |excluded| full_description.include?(excluded) }

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
    return if RSpec.world.wants_to_quit

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

    begin
      # Make GET request to the link using the RSpec context
      @context.get link
    # We ignore errors because some specs are designed to inject invalid data, etc, so other
    # views to which we reach out may in fact be corrupted
    rescue StandardError
      return
    end

    # The test will fail automatically if the GET request returns an error status
    @context
      .expect(ALLOWED_RESPONSES)
      .to(
        @context.include(@context.response.status),
        "Link '#{link}' returned #{@context.response.status} status"
      )
  end

  # Builds a visit key so we track similar links and do not visit similar stuff twice
  # @param link [String]
  # @return [String]
  def visit_key(link)
    final_key = link.dup

    KEY_TRANSFORMERS.each do |transformer|
      final_key = final_key.gsub(transformer, 'KEY')
    end

    final_key
  end
end
