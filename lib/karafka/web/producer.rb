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
    # - Creates a variant with `acks: 0` (fire-and-forget) for non-idempotent, non-transactional
    #   producers to minimize the overhead of the non-critical reporting traffic
    #
    # For the occasional produce where the assigned offset matters (a user-initiated publish, not
    # reporting), use {#acked} to get an `acks: 1` variant instead.
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
      # @note accept block to avoid Ruby 3.4's `strict_unused_block` warning from SimpleDelegator.
      def __getobj__(&)
        unless @initialized
          @delegate_sd_obj = acks_variant(0)
          @initialized = true
        end

        @delegate_sd_obj
      end

      # A producer variant that waits for a broker acknowledgment (`acks: 1`) so the delivery
      # report carries a real offset. Use it for user-initiated produces where the assigned offset
      # matters, rather than the default fire-and-forget reporting producer.
      #
      # @return [WaterDrop::Producer, WaterDrop::Producer::Variant] the `acks: 1` variant, or the
      #   default producer unchanged when it is idempotent/transactional (already `acks: all`)
      def acked
        @acked ||= acks_variant(1)
      end

      private

      # Builds an `acks`-adjusted variant of the default producer, when altering acks is allowed
      #
      # @param acks [Integer] required acknowledgments for the variant
      # @return [WaterDrop::Producer, WaterDrop::Producer::Variant] the variant, or the default
      #   producer unchanged for idempotent/transactional producers (acks cannot be altered - they
      #   require acks: all)
      def acks_variant(acks)
        default = ::Karafka.producer

        return default if default.idempotent?
        return default if default.transactional?

        default.variant(topic_config: { acks: acks })
      end
    end
  end
end
