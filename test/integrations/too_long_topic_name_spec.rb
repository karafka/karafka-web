# frozen_string_literal: true

# Verifies that looking up a topic whose name is longer than Kafka allows (249 characters) gives
# the Web UI "not found" error without querying the cluster. With a name over 512 characters
# karafka-rdkafka 0.32.2 and older crash the whole process with a segmentation fault.
#
# Needs Kafka at `KAFKA_BOOTSTRAP_SERVERS` (default: 127.0.0.1:9092).

require "bundler/setup"
require "securerandom"
require "karafka"
require "karafka/web"
require_relative "helper"

include IntegrationHelper

class KarafkaApp < Karafka::App
  setup do |config|
    config.kafka = { "bootstrap.servers": ENV.fetch("KAFKA_BOOTSTRAP_SERVERS", "127.0.0.1:9092") }
    config.client_id = "it-too-long-topic-name-#{SecureRandom.hex(6)}"
  end
end

[513, 250].each do |length|
  not_found = begin
    Karafka::Web::Ui::Models::ClusterInfo.topic("a" * length)
    false
  rescue Karafka::Web::Errors::Ui::NotFoundError
    true
  end

  assert(not_found, "A #{length} characters topic name should not be found")
end

puts "Too long topic name: OK"
