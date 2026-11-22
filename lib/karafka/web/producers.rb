# frozen_string_literal: true

module Karafka
  module Web
    # Facade over the producers the Web UI dispatches through
    module Producers
      # `acks: all` variants of custom producers, built once per producer
      FULLY_ACKED = {}.compare_by_identity

      # Guards the variants building
      FULLY_ACKED_LOCK = Mutex.new

      private_constant :FULLY_ACKED, :FULLY_ACKED_LOCK

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

        # @return [WaterDrop::Producer, WaterDrop::Producer::Variant] a variant that waits for all
        #   the in-sync replicas (`acks: all`). For a custom producer it is built from it, unless
        #   the producer is idempotent or transactional (those already use `acks: all`).
        def fully_acked
          producer = default

          return producer.fully_acked if producer.respond_to?(:fully_acked)

          base = producer.is_a?(WaterDrop::Producer::Variant) ? producer.producer : producer

          return base if base.idempotent? || base.transactional?

          topic_config = producer.is_a?(WaterDrop::Producer::Variant) ? producer.topic_config : {}

          FULLY_ACKED_LOCK.synchronize do
            FULLY_ACKED[producer] ||= base.variant(topic_config: topic_config.merge(acks: "all"))
          end
        end
      end
    end
  end
end
