# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Producers
        module Listeners
          # Listener for tracking producers published errors
          class Errors < Base
            include Tracking::Helpers::ErrorInfo

            # Schema used by producers error reporting
            SCHEMA_VERSION = '1.1.0'

            private_constant :SCHEMA_VERSION

            # Tracks any producer related errors
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_error_occurred(event)
              track do |sampler|
                sampler.errors << build_error_details(event)
              end
            end

            private

            # @param event [Karafka::Core::Monitoring::Event]
            # @return [Hash] hash with error data for the sampler
            def build_error_details(event)
              type = event[:type]

              error_class, error_message, backtrace = extract_error_info(event[:error])

              {
                schema_version: SCHEMA_VERSION,
                producer_id: event[:producer_id],
                type: type,
                error_class: error_class,
                error_message: error_message,
                backtrace: backtrace,
                details: build_details(type, event.payload),
                occurred_at: float_now,
                process: {
                  id: sampler.process_id
                }
              }
            end

            # @param type [String] error type
            # @param payload [Hash] error payload
            # @return [Hash] hash with details
            def build_details(type, payload)
              case type
              when 'librdkafka.dispatch_error'
                payload.slice(:topic, :partition, :offset)
              else
                {}
              end
            end
          end
        end
      end
    end
  end
end
