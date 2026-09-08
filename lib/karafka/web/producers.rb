# frozen_string_literal: true

module Karafka
  module Web
    # Facade over the producers the Web UI dispatches through
    module Producers
      class << self
        # @return [WaterDrop::Producer, nil] the configured Web UI producer (a fire-and-forget
        #   `acks: 0` reporting producer by default). Alias of {Karafka::Web.producer}.
        def default
          Web.producer
        end

        # @return [WaterDrop::Producer] a variant that waits for at least one broker
        #   acknowledgement (`acks: 1`), so user-initiated produces are confirmed rather than
        #   fire-and-forget. Falls back to {.default} when it does not expose an acked variant
        #   (for example a custom user-provided producer).
        def acked
          default.respond_to?(:acked) ? default.acked : default
        end
      end
    end
  end
end
