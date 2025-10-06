# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        class Sampler < Tracking::Sampler
          # Namespace for metrics collectors that gather various system and process statistics
          module Metrics
            # Base class for metrics collectors
            class Base
            end
          end
        end
      end
    end
  end
end
