# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        # Consumer monitoring related listeners
        module Listeners
          # Base consumers processes related listener
          class Base
            include ::Karafka::Core::Helpers::Time
            extend Forwardable

            def_delegators :sampler, :track
            def_delegators :reporter, :report, :report!

            private

            # @return [Object] sampler in use
            def sampler
              @sampler ||= ::Karafka::Web.config.tracking.consumers.sampler
            end

            # @return [Object] reporter in use
            def reporter
              @reporter ||= ::Karafka::Web.config.tracking.consumers.reporter
            end
          end
        end
      end
    end
  end
end
