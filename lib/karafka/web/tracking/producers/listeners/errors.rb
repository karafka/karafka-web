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
            SCHEMA_VERSION = "1.2.0"

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
                id: SecureRandom.uuid,
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
              when "librdkafka.dispatch_error"
                payload
                  .slice(:topic, :partition, :offset)
                  .merge(delivery_details(payload[:delivery_report]))
              else
                {}
              end
            end

            # @param delivery_report [Rdkafka::Producer::DeliveryReport, nil] report of the
            #   failed delivery
            # @return [Hash] delivery outcome details or an empty hash when the report does not
            #   carry them (karafka-rdkafka older than 0.31.0)
            def delivery_details(delivery_report)
              return {} unless delivery_report.respond_to?(:status)

              latency = delivery_report.latency

              {
                delivery_status: delivery_status(delivery_report),
                latency_ms: latency && (latency / 1_000.0).round(2),
                broker_id: delivery_report.broker_id
              }
            end

            # @param delivery_report [Rdkafka::Producer::DeliveryReport] report of the failed
            #   delivery
            # @return [String, nil] persistence status of the message or nil when not known
            def delivery_status(delivery_report)
              if delivery_report.not_persisted?
                "not persisted"
              elsif delivery_report.possibly_persisted?
                "possibly persisted"
              elsif delivery_report.persisted?
                "persisted"
              end
            end
          end
        end
      end
    end
  end
end
