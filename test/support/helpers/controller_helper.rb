# frozen_string_literal: true

# Extra methods for controller helpers
module ControllerHelper
  include Karafka::Web::Tracking::Helpers::ErrorInfo

  # @return [String] response body
  def body
    response.body
  end

  # @return [Hash] response headers
  def headers
    response.headers
  end

  # @return [Hash] sanitized flash messages hash or nil if none
  # @note We sanitize it because of auto-wrapping of some parts with bold
  def flash
    env_key = Karafka::Web.config.ui.sessions.env_key

    last_request
      .env[env_key]["_flash"]
      .transform_values { |value| value.gsub("<strong>", "").gsub("</strong>", "") }
  end

  # @return [Karafka::Core::Configurable::Node] topics config node
  def topics_config
    Karafka::Web.config.topics
  end

  # @return [Rack::MockResponse] mock rack response
  def response
    last_response
  end

  # @return [String]
  def only_pro_feature
    "This feature is available only to"
  end

  # @return [String] Message we display for offsets without user data
  def compacted_or_transactional_offset
    <<~MSG.tr("\n", " ").strip
      This offset does not contain any data.
      The message may have been compacted or is a system entry.
    MSG
  end

  # @return [Integer] http response status
  def status
    response.status
  end

  # Asserts that the response body includes the expected string
  # @param expected [String] expected substring
  def assert_body(expected)
    assert_includes(body, expected)
  end

  # Refutes that the response body includes the expected string
  # @param expected [String] expected substring
  def refute_body(expected)
    refute_includes(body, expected)
  end

  # Asserts that the response is successful (2xx), printing the actual status and a body excerpt
  # on failure instead of a bare "Expected false to be truthy". A plain `assert(response.ok?)`
  # gives no clue whether a failure is a 404, a 500, or something else, which makes intermittent
  # CI-only failures much harder to diagnose than they need to be.
  #
  # On a 500, also includes every actual exception (class, message, trimmed backtrace, and the
  # Rdkafka error code when applicable) captured via the `error.occurred` monitor event (see
  # `LastUiError` in test_helper.rb) instead of just the generic static error page body, which is
  # otherwise the only thing a failure here shows.
  def assert_ok
    message = "Expected a successful response, got #{status}. Body excerpt: #{body[0, 500].inspect}"
    message += captured_errors_report

    assert(response.ok?, message)
  end

  # @return [String] breadcrumbs string part to match for presence
  def breadcrumbs
    '<div class="breadcrumbs">'
  end

  # @return [String] pagination matching string
  def pagination
    'id="pagination"'
  end

  # @return [String] no results on pagination string
  def no_meaningful_results
    "first page to get meaningful results"
  end

  private

  # @return [String] formatted report of all Web UI errors captured during this test via
  #   `LastUiError` (empty string if none were captured)
  def captured_errors_report
    LastUiError.errors.map { |error| format_captured_error(error) }.join
  end

  # @param error [StandardError] captured error to format
  # @return [String] single formatted error report with a trimmed backtrace (app/gem root paths
  #   stripped, same formatting as what would show up on the Errors UI page for this error)
  # @note `Rdkafka::RdkafkaError` is deliberately not special-cased here: the production error
  #   handler already converts it to a 404 before it ever reaches the `error.occurred`
  #   instrumentation this capture relies on, so it can never actually be one of these.
  def format_captured_error(error)
    _klass, message, backtrace = extract_error_info(error)

    "\nCaptured error: #{error.class}: #{message}\n#{backtrace.lines.first(15).join}"
  end
end
