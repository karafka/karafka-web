# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if we can connect to Kafka and measures connection latency.
            #
            # Some users try to work with Kafka over the internet with high latency,
            # which can make the connection unstable. This check measures connection
            # time and warns when it's too high.
            #
            # Connection times:
            # - < 1 second: success
            # - 1-1000 seconds: warning (high latency)
            # - > 1000 seconds or failure: failure
            class Connection < Base
              depends_on :enabled

              class << self
                # @return [Hash] the default details for halted state
                def halted_details
                  { time: nil }
                end
              end

              # Executes the connection check.
              #
              # Attempts to connect to Kafka and measures the connection time.
              # Caches the result in the context for subsequent checks.
              #
              # @return [Status::Step] result with connection time in details
              def call
                connect unless context.connection_time

                level = if context.connection_time < 1_000
                  :success
                elsif context.connection_time < 1_000_000
                  :warning
                else
                  :failure
                end

                step(level, { time: context.connection_time })
              end

              private

              # Attempts to connect to Kafka and stores connection info in context.
              #
              # On success, stores cluster_info and connection_time.
              # On failure, sets connection_time to 1_000_000 (indicating failure).
              def connect
                started = Time.now.to_f
                context.cluster_info = Models::ClusterInfo.fetch
                context.connection_time = (Time.now.to_f - started) * 1_000
              rescue ::Rdkafka::RdkafkaError
                context.connection_time = 1_000_000
              end
            end
          end
        end
      end
    end
  end
end
