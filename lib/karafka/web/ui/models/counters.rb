# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Represents the top counters bar values on the consumers view
        class Counters < Lib::HashProxy
          # @param state [Hash]
          def initialize(state)
            super(state[:stats])
            @hash[:errors] = estimate_errors_count
          end

          # @return [Integer] number of jobs that are not yet running. This includes jobs on the
          #   workers queue as well as jobs in the scheduling
          def pending
            enqueued + waiting
          end

          private

          # Estimates the number of errors present in the errors topic.
          #
          # Uses a single targeted metadata call to discover partition count followed by one
          # batch ListOffsets admin call, rather than up to N sequential per-partition
          # query_watermark_offsets consumer calls. This avoids opening a consumer connection
          # and eliminates the N sequential Kafka roundtrips.
          def estimate_errors_count
            errors_topic = ::Karafka::Web.config.topics.errors.name

            begin
              info = ::Karafka::Admin.topic_info(errors_topic)
            rescue Rdkafka::RdkafkaError => e
              return 0 if e.code == :unknown_topic_or_part

              raise
            end

            partition_count = info[:partition_count]
            return 0 if partition_count.zero?

            partition_ids = (0...partition_count).to_a
            all_offsets = ::Karafka::Admin.read_watermark_offsets(errors_topic => partition_ids)

            partition_ids.sum do |partition_id|
              low, high = all_offsets.dig(errors_topic, partition_id) || [0, 0]
              high - low
            end
          end
        end
      end
    end
  end
end
