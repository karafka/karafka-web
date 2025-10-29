# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        class Sampler < Tracking::Sampler
          # Namespace for data enrichers that augment sampler data with additional details
          module Enrichers
            # Base class for data enrichers
            # This is an abstract base class that can be extended to create custom enrichers
            class Base
              # Placeholder for future common functionality
            end
          end
        end
      end
    end
  end
end
