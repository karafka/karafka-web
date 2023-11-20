# frozen_string_literal: true

# Extra methods for topics management in specs
module TopicsManagerHelper
  # @param topic_name [String] topic name. Default will generate automatically
  # @param partitions [Integer] number of partitions (one by default)
  # @return [String] generated topic name
  def create_topic(topic_name: SecureRandom.uuid, partitions: 1)
    Karafka::Admin.create_topic(topic_name, partitions, 1)
    topic_name
  end

  # Sends data to Kafka in a sync way
  # @param topic [String] topic name
  # @param payload [String, nil] data we want to send
  # @param details [Hash] other details
  def produce(topic, payload = SecureRandom.uuid, details = {})
    type = details.delete(:type) || :regular

    PRODUCERS.public_send(type).produce_sync(
      **details.merge(
        topic: topic,
        payload: payload
      )
    )
  end

  # Sends multiple messages to kafka efficiently
  # @param topic [String] topic name
  # @param payloads [Array<String, nil>] data we want to send
  # @param details [Hash] other details
  def produce_many(topic, payloads, details = {})
    type = details.delete(:type) || :regular

    messages = payloads.map { |payload| details.merge(topic: topic, payload: payload) }

    PRODUCERS.public_send(type).produce_many_sync(messages)
  end
end
