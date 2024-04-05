# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      # Namespace for all the things related to tracking producers
      module Producers
        # Samples for collecting producers related data we're interested in
        class Sampler < Tracking::Sampler
          include ::Karafka::Core::Helpers::Time

          attr_reader :errors

          # Current schema version
          # This can be used in the future for detecting incompatible changes and writing
          # migrations
          SCHEMA_VERSION = '1.1.0'

          def initialize
            super

            @errors = []
            @started_at = float_now
          end

          # We cannot report and track the same time, that is why we use mutex here. To make sure
          # that samples aggregations and counting does not interact with reporter flushing.
          def track
            # Prevents deadlocks when something producer related fails in the Web UI reporter
            return yield(self) if Reporter::MUTEX.owned?

            Reporter::MUTEX.synchronize do
              yield(self)
            end
          end

          # Clears the sampler (for use after data dispatch)
          def clear
            @errors.clear
          end
        end
      end
    end
  end
end
