# frozen_string_literal: true

module Factories
  # Factories for routing objects (topic, consumer_group, subscription_group)
  module Routing
    module_function

    # @param name [String] consumer group name
    # @return [Karafka::Routing::ConsumerGroup]
    def build_consumer_group(name: "group-name", **)
      Karafka::Routing::ConsumerGroup.new(name)
    end

    # @param name [String] topic name
    # @param consumer_group [Karafka::Routing::ConsumerGroup] consumer group
    # @param consumer [Class] consumer class
    # @param subscription_group [String] subscription group id
    # @param subscription_group_details [Hash] subscription group details
    # @return [Karafka::Routing::Topic]
    def build_topic(
      name: "test",
      consumer_group: nil,
      consumer: nil,
      subscription_group: nil,
      subscription_group_details: nil,
      **
    )
      consumer_group ||= build_consumer_group
      consumer ||= Class.new(Karafka::BaseConsumer)
      subscription_group ||= SecureRandom.hex(6)
      subscription_group_details ||= { name: SecureRandom.uuid }

      instance = Karafka::Routing::Topic.new(name, consumer_group)
      instance.consumer = consumer
      instance.subscription_group = subscription_group
      instance.subscription_group_details = subscription_group_details
      instance
    end

    # @param topics [Array<Karafka::Routing::Topic>] topics
    # @return [Karafka::Routing::SubscriptionGroup]
    def build_subscription_group(topics: nil, **)
      topics ||= [build_topic]
      Karafka::Routing::SubscriptionGroup.new(0, topics)
    end
  end
end
