# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      # Namespace for UI specific tracking
      module Ui
        # Listener for tracking and reporting Web UI errors directly to Kafka
        #
        # Unlike consumer and producer errors that are collected in samplers and dispatched
        # periodically, UI errors need to be dispatched immediately and asynchronously from
        # the web process (Puma/Rack) since there's no background reporter running in the web UI.
        class Errors
          include ::Karafka::Core::Helpers::Time
          include Tracking::Helpers::ErrorInfo

          # Schema used by UI error reporting
          SCHEMA_VERSION = '1.1.0'

          private_constant :SCHEMA_VERSION

          # Tracks any UI related errors and dispatches them to Kafka
          #
          # @param event [Karafka::Core::Monitoring::Event]
          def on_error_occurred(event)
            # Only process UI errors, ignore all other error types
            return unless event[:type] == 'web.ui.error'

            error_class, error_message, backtrace = extract_error_info(event[:error])

            error_data = {
              schema_version: SCHEMA_VERSION,
              type: event[:type],
              error_class: error_class,
              error_message: error_message,
              backtrace: backtrace,
              details: {},
              occurred_at: float_now,
              process: {
                id: process_id
              }
            }

            # Validate the error data
            Tracking::Contracts::Error.new.validate!(error_data)

            # Dispatch error to Kafka asynchronously
            dispatch(error_data)
          rescue StandardError => e
            # If we fail to report an error, log it but don't raise to avoid error loops
            ::Karafka.logger.error("Failed to report UI error: #{e.message}")
          end

          private

          # @return [String] unique process identifier
          def process_id
            @process_id ||= Tracking::Sampler.new.process_id
          end

          # Dispatches error to Kafka
          # @param error_data [Hash] error data to dispatch
          def dispatch(error_data)
            ::Karafka::Web.producer.produce_async(
              topic: ::Karafka::Web.config.topics.errors.name,
              payload: Zlib::Deflate.deflate(error_data.to_json),
              key: process_id,
              headers: { 'zlib' => 'true' }
            )
          end
        end
      end
    end
  end
end
