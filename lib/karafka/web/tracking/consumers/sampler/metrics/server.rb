# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        class Sampler < Tracking::Sampler
          module Metrics
            # Collects Karafka server state metrics (listeners, workers, status)
            class Server < Base
              # @return [Hash] number of active and standby listeners
              def listeners
                if Karafka::Server.listeners
                  active = Karafka::Server.listeners.count(&:active?)
                  total = Karafka::Server.listeners.count.to_i

                  { active: active, standby: total - active }
                else
                  { active: 0, standby: 0 }
                end
              end

              # @return [Integer] number of threads that process work
              def workers
                Karafka::App.config.concurrency
              end
            end
          end
        end
      end
    end
  end
end
