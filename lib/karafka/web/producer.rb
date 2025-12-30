# frozen_string_literal: true

module Karafka
  module Web
    # A lazy-evaluated producer wrapper that creates a low-intensity variant of the default
    # Karafka producer when possible.
    #
    # Web UI reporting is not mission-critical and serves primarily analytical purposes.
    # Users typically want stronger delivery warranties for their business producers.
    # For web UI reporting, we can use lower acknowledgment levels to reduce overhead.
    #
    # This wrapper:
    # - Returns the default producer unchanged if it's idempotent or transactional
    #   (since acks cannot be altered for these producer types)
    # - Creates a variant with `acks: 1` for non-idempotent, non-transactional producers
    #   to reduce latency while maintaining basic delivery confirmation
    #
    # @note This uses SimpleDelegator to transparently proxy all producer methods
    # @note The variant is created lazily on first access to ensure the default producer
    #   is fully initialized
    class Producer < SimpleDelegator
      def initialize
        @initialized = false
        # Initialize with nil - will be set on first access
        super(nil)
      end

      # @return [WaterDrop::Producer, WaterDrop::Producer::Variant] the underlying producer
      #   or its low-ack variant
      def __getobj__
        unless @initialized
          @delegate_sd_obj = build_producer
          @initialized = true
        end

        @delegate_sd_obj
      end

      private

      # Builds the appropriate producer based on the default producer's configuration
      #
      # @return [WaterDrop::Producer, WaterDrop::Producer::Variant] either the default producer
      #   (if idempotent/transactional) or a low-ack variant
      def build_producer
        default = ::Karafka.producer

        # Idempotent producers require acks: all - cannot create variants with different acks
        return default if default.idempotent?
        # Transactional producers also require acks: all
        return default if default.transactional?

        # For non-idempotent, non-transactional producers, create a variant with lower acks
        # acks: 0 means fire-and-forget - no acknowledgment required
        # This is acceptable for non-critical analytics/monitoring data where occasional
        # message loss is not a concern
        default.variant(topic_config: { acks: 0 })
      end
    end
  end
end
