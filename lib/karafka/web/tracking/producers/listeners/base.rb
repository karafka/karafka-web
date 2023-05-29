# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Producers
        # Namespace for producers listeners
        module Listeners
          # Base listener for producer related listeners
          class Base
            include ::Karafka::Core::Helpers::Time
            extend Forwardable

            def_delegators :sampler, :track
            def_delegators :reporter, :report, :report!

            private

            # @return [Object] sampler in use
            def sampler
              @sampler ||= ::Karafka::Web.config.tracking.producers.sampler
            end

            # @return [Object] reporter in use
            def reporter
              @reporter ||= ::Karafka::Web.config.tracking.producers.reporter
            end
          end
        end
      end
    end
  end
end
