# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      # Namespace for all the things related to tracking producers
      module Producers
        # Samples for fetching and storing metrics samples about the producers
        class Sampler < Tracking::Sampler
          include ::Karafka::Core::Helpers::Time

          attr_reader :errors, :producers

          # Current schema version
          # This can be used in the future for detecting incompatible changes and writing
          # migrations
          SCHEMA_VERSION = '1.0.0'

          def initialize
            super

            @errors = []
            @started_at = float_now
          end

          # We cannot report and track the same time, that is why we use mutex here. To make sure
          # that samples aggregations and counting does not interact with reporter flushing.
          def track
            Reporter::MUTEX.synchronize do
              yield(self)
            end
          end

          def clear
            @errors.clear
          end
        end
      end
    end
  end
end
