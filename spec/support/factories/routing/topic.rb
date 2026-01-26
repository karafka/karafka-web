# frozen_string_literal: true

FactoryBot.define do
  factory :routing_topic, class: "Karafka::Routing::Topic" do
    consumer_group { build(:routing_consumer_group) }
    name { "test" }
    consumer { Class.new(Karafka::BaseConsumer) }
    kafka { {} }
    max_messages { 1000 }
    max_wait_time { 10_000 }
    subscription_group { SecureRandom.hex(6) }
    subscription_group_details { { name: SecureRandom.uuid } }

    skip_create

    initialize_with do
      instance = new(name, consumer_group)

      instance.tap do |topic|
        topic.consumer = consumer
        topic.subscription_group = subscription_group
        topic.subscription_group_details = subscription_group_details
      end
    end
  end
end
