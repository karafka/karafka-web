# frozen_string_literal: true

# Verifies that the Web UI rejects a topic name Kafka cannot have (over 249 characters, characters
# outside `[A-Za-z0-9._-]`, `.` or `..`) with its "not found" error, without querying the cluster.
# A cluster call with such a name can wait up to 60 seconds.
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
    config.client_id = "it-invalid-topic-name-#{SecureRandom.hex(6)}"
  end
end

def not_found?
  yield
  false
rescue Karafka::Web::Errors::Ui::NotFoundError
  true
end

started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

["a" * 513, "a" * 250, "a b", ".."].each do |topic_name|
  assert(
    not_found? { Karafka::Web::Ui::Models::ClusterInfo.topic(topic_name) },
    "Topic #{topic_name[0, 20].inspect} (#{topic_name.size} chars) should not be found"
  )

  assert(
    not_found? { Karafka::Web::Ui::Models::WatermarkOffsets.find(topic_name, 0) },
    "Watermark offsets of #{topic_name[0, 20].inspect} should not be found"
  )
end

elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at

assert(elapsed < 1, "Invalid topic names should be rejected without cluster calls (#{elapsed}s)")

puts "Invalid topic name: OK"
