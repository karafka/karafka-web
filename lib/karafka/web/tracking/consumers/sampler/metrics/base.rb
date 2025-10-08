# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        class Sampler < Tracking::Sampler
          # Namespace for metrics collectors that gather various system and process statistics
          module Metrics
            # Base class for metrics collectors
            # This is an abstract base class that can be extended to create custom metrics collectors
            class Base
              # Placeholder for future common functionality
            end
          end
        end
      end
    end
  end
end
