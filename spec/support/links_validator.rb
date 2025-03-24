# frozen_string_literal: true

# Simple validator that extracts all the links rendered after each page and visits them to make
# sure, that we do not have any dead links.
#
# @note This process can be time consuming. You can set `KARAFKA_SPECS_VALIDATE_LINKS` to false to
#   skip those when running specs.

class LinksValidator
  include Singleton

  # 200 - ok
  # 302, 304 - redirects
  # 402 - paid pro feature
  ALLOWED_RESPONSES = [200, 302, 304, 402].freeze

  # Cases that are hardcoded or come from fixtures that are always 404 or are expected to fail
  # in other ways
  EXCEPTIONS = [
    /explorer\/topics\/\w+\/\d+/,
    /explorer\/topics\/it-[a-f0-9-]+\/\d+/
  ].freeze

  private_constant :ALLOWED_RESPONSES

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

    # Filter to only include internal links (not external or anchors)
    links.select do |link|
      next if link.start_with?('#', 'http://', 'https://', 'mailto:', 'tel:')
      next if link.empty?

      true
    end
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

    # Skip if we've already visited this link
    return if @visited_links.include?(link)

    # Add to visited set to avoid checking again
    @visited_links.add(link)

    # Make GET request to the link using the RSpec context
    @context.get link

    # The test will fail automatically if the GET request returns an error status
    @context
      .expect(ALLOWED_RESPONSES)
      .to(
        @context.include(@context.response.status),
        "Link '#{link}' returned #{@context.response.status} status"
      )
  end
end
