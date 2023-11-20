# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Represents the top counters bar values on the consumers view
        class Counters < Lib::HashProxy
          # Max errors partitions we support for estimations
          MAX_ERROR_PARTITIONS = 100

          private_constant :MAX_ERROR_PARTITIONS

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
          def estimate_errors_count
            estimated = 0

            MAX_ERROR_PARTITIONS.times do |partition|
              begin
                offsets = Lib::Admin.read_watermark_offsets(
                  ::Karafka::Web.config.topics.errors,
                  partition
                )
              # We estimate that way instead of using `#cluster_info` to get the partitions count
              # inside the errors topic, because it is around 90x faster to query for invalid
              # partition and get the error, instead of querying for all topics on a big cluster
              #
              # Most of the users use one or few error partitions at most, so this is fairly
              # efficient and not problematic
              rescue Rdkafka::RdkafkaError => e
                e.code == :unknown_partition ? break : raise
              end

              estimated += offsets.last - offsets.first
            end

            estimated
          end
        end
      end
    end
  end
end
