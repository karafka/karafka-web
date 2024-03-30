# frozen_string_literal: true

FactoryBot.define do
  factory :consumer, class: 'Karafka::BaseConsumer' do
    messages do
      OpenStruct.new(
        size: 1,
        metadata: batch_metadata
      )
    end

    transient do
      batch_metadata do
        Karafka::Messages::BatchMetadata.new(
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
      end

      coordinator { build(:processing_coordinator, seek_offset: 1) }
    end

    skip_create

    initialize_with do
      consumer = new
      consumer.messages = messages
      consumer.coordinator = coordinator
      consumer
    end
  end
end
