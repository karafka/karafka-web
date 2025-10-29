# frozen_string_literal: true

# Extra methods for topics management in specs
module TopicsManagerHelper
  # @return [String] random name of a topic with the integration suite prefix
  def generate_topic_name
    "it-#{SecureRandom.uuid}"
  end

  # @param topic_name [String] topic name. Default will generate automatically
  # @param partitions [Integer] number of partitions (one by default)
  # @return [String] generated topic name
  def create_topic(topic_name: generate_topic_name, partitions: 1)
    Karafka::Admin.create_topic(topic_name, partitions, 1)

    # Topic synchronization may take some time, especially when there are hundreds of partitions,
    # hence we check if topic is available and if not we wait
    # Slow topic creation can happen especially on CI
    loop do
      topics = Karafka::Admin.cluster_info.topics
      found = topics.find { |topic| topic[:topic_name] == topic_name }

      break if found

      sleep(0.1)
    end

    topic_name
  end

  # Sends data to Kafka in a sync way
  # @param topic [String] topic name
  # @param payload [String, nil] data we want to send
  # @param details [Hash] other details
  def produce(topic, payload = SecureRandom.uuid, details = {})
    type = details.delete(:type) || :regular

    PRODUCERS.public_send(type).produce_sync(
      **details,
      topic: topic,
      payload: payload
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

  # Draws expected routes
  def draw_routes(&)
    Karafka::App.routes.draw(&)
  end
end
