# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        class Sampler < Tracking::Sampler
          # Namespace for data enrichers that augment sampler data with additional details
          module Enrichers
            # Base class for data enrichers
            class Base
            end
          end
        end
      end
    end
  end
end
