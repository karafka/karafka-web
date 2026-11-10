# frozen_string_literal: true

# Verifies that with `active_topics_cluster_lags_only = false` the Health cluster lags also show
# topics outside the Web UI routing for which a routed consumer group has committed offsets,
# while the default keeps them out.
#
# Needs Kafka at `KAFKA_BOOTSTRAP_SERVERS` (default: 127.0.0.1:9092).

require "bundler/setup"
require "securerandom"
require "karafka"
require "karafka/web"
require_relative "helper"

include IntegrationHelper

BOOTSTRAP_SERVERS = ENV.fetch("KAFKA_BOOTSTRAP_SERVERS", "127.0.0.1:9092")
SUFFIX = SecureRandom.hex(6)
CONSUMER_GROUP = "it-cluster-lags-#{SUFFIX}"
ROUTED_TOPIC = "it-cluster-lags-routed-#{SUFFIX}"
OUTSIDE_TOPIC = "it-cluster-lags-outside-#{SUFFIX}"
UNCOMMITTED_TOPIC = "it-cluster-lags-uncommitted-#{SUFFIX}"

class KarafkaApp < Karafka::App
  setup do |config|
    config.kafka = { "bootstrap.servers": BOOTSTRAP_SERVERS }
    config.client_id = CONSUMER_GROUP
  end

  routes.draw do
    consumer_group CONSUMER_GROUP do
      topic ROUTED_TOPIC do
        consumer Karafka::BaseConsumer
      end
    end
  end
end

Karafka::Web.setup do |config|
  config.ui.sessions.secret = SecureRandom.hex(64)
  config.group_id = "it-cluster-lags-web-#{SUFFIX}"
end

# Kafka may still be starting when this scenario runs in its own container
created = 30.times.any? do
  Karafka::Admin.create_topic(ROUTED_TOPIC, 1, 1)
  true
rescue Rdkafka::RdkafkaError
  sleep(2)
  false
end

assert(created, "Kafka should be reachable")

Karafka::Admin.create_topic(OUTSIDE_TOPIC, 1, 1)
Karafka::Admin.create_topic(UNCOMMITTED_TOPIC, 1, 1)

sleep(0.1) until (
  Karafka::Admin.cluster_info.topics.map { |topic| topic[:topic_name] } &
  [ROUTED_TOPIC, OUTSIDE_TOPIC, UNCOMMITTED_TOPIC]
).size == 3

Karafka.producer.produce_many_sync(
  Array.new(10) { { topic: OUTSIDE_TOPIC, payload: SecureRandom.uuid } }
)

Karafka::Admin.seek_consumer_group(CONSUMER_GROUP, OUTSIDE_TOPIC => { 0 => 4 })

visibility = Karafka::Web.config.ui.visibility

active_only = Karafka::Web::Ui::Models::Health.cluster_lags_with_offsets.fetch(CONSUMER_GROUP)

assert_equal([ROUTED_TOPIC], active_only.keys, "Only routed topics should show by default")

visibility.active_topics_cluster_lags_only = false
all_topics = Karafka::Web::Ui::Models::Health.cluster_lags_with_offsets.fetch(CONSUMER_GROUP)

assert_equal(
  [OUTSIDE_TOPIC, ROUTED_TOPIC].sort,
  all_topics.keys,
  "Topics with committed offsets outside the routing should show"
)

assert_equal(
  [{ id: 0, lag: 6, stored_offset: 4 }],
  all_topics.fetch(OUTSIDE_TOPIC),
  "The topic outside the routing should have its real lag and offset"
)

puts "Cluster lags outside the routing: OK"
