# frozen_string_literal: true

module Factories
  # Factory for building time tracker pause instances
  module TimeTrackers
    module_function

    # @param timeout [Integer] timeout in ms
    # @param max_timeout [Integer] max timeout in ms
    # @param exponential_backoff [Boolean] use exponential backoff
    # @return [Karafka::TimeTrackers::Pause]
    def build_pause(timeout: 500, max_timeout: 1_000, exponential_backoff: true, **)
      Karafka::TimeTrackers::Pause.new(
        timeout: timeout,
        max_timeout: max_timeout,
        exponential_backoff: exponential_backoff
      )
    end
  end
end
