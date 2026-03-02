# frozen_string_literal: true

module Factories
  # Factory for building Karafka::BaseConsumer instances
  module Consumer
    module_function

    # @param coordinator [Object] coordinator instance
    # @param messages [Object] messages instance
    # @return [Karafka::BaseConsumer] a consumer instance
    def build(coordinator: nil, messages: nil, **)
      coordinator ||= Factories::Processing.build_coordinator(seek_offset: 1)

      batch_metadata = Karafka::Messages::BatchMetadata.new(
        size: 10,
        first_offset: 0,
        last_offset: 1,
        deserializers: nil,
        partition: 1,
        topic: coordinator.topic.name,
        created_at: Time.now,
        scheduled_at: Time.now - 1,
        processed_at: Time.now
      )

      messages ||= Struct.new(:size, :metadata).new(1, batch_metadata)

      consumer = Karafka::BaseConsumer.new
      consumer.messages = messages
      consumer.coordinator = coordinator
      consumer
    end
  end
end
