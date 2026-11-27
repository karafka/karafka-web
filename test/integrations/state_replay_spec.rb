# frozen_string_literal: true

# Verifies that the Web UI totals are not counted twice when a restarted server consumes the
# consumers reports again. On shutdown the Web UI consumer stores the state but does not mark the
# reports as consumed, so the next server replays them from the last committed offset.
#
# Needs Kafka at `KAFKA_BOOTSTRAP_SERVERS` (default: 127.0.0.1:9092).

require "bundler/setup"
require "json"
require "securerandom"
require "tmpdir"
require "timeout"
require "zlib"
require_relative "helper"

include IntegrationHelper

dir = Dir.mktmpdir
boot_file = File.join(dir, "karafka.rb")
suffix = SecureRandom.hex(6)

File.write(boot_file, <<~RUBY)
  # frozen_string_literal: true

  require "karafka"
  require "karafka/web"

  TOPIC = "it-state-replay-#{suffix}"

  class KarafkaApp < Karafka::App
    setup do |config|
      config.kafka = { "bootstrap.servers": ENV.fetch("KAFKA_BOOTSTRAP_SERVERS", "127.0.0.1:9092") }
      config.client_id = "it-state-replay-#{suffix}"
      config.shutdown_timeout = 20_000
    end

    routes.draw do
      topic TOPIC do
        consumer Class.new(Karafka::BaseConsumer) { def consume; end }
      end
    end
  end

  Karafka::Web.setup do |config|
    config.ui.sessions.secret = "#{SecureRandom.hex(64)}"
    config.group_id = "it-state-replay-web-#{suffix}"
    config.topics.errors.name = "it-state-replay-errors-#{suffix}"
    config.topics.consumers.reports.name = "it-state-replay-reports-#{suffix}"
    config.topics.consumers.states.name = "it-state-replay-states-#{suffix}"
    config.topics.consumers.metrics.name = "it-state-replay-metrics-#{suffix}"
    config.topics.consumers.commands.name = "it-state-replay-commands-#{suffix}"
    config.tracking.interval = 1_000
    # Only the first flush after the warm-up marks the reports as consumed within this scenario
    config.processing.interval = 60_000
  end

  Karafka::Web.enable!
RUBY

ENV["KARAFKA_BOOT_FILE"] = boot_file
require boot_file

# Kafka may still be starting when this scenario runs in its own container
installed = 30.times.any? do
  Karafka::Web::Installer.new.install
  true
rescue Rdkafka::RdkafkaError, Rdkafka::AbstractHandle::WaitTimeoutError
  sleep(2)
  false
end

assert(installed, "Web UI install should succeed")

reports_topic = Karafka::Web.config.topics.consumers.reports.name
log = File.join(dir, "server.log")

start_server = -> { Process.spawn("bundle", "exec", "karafka", "server", out: log, err: log) }

stop_server = lambda do |pid|
  Process.kill("TERM", pid)
  Process.wait(pid)
end

current_state = -> { Karafka::Web::Processing::Consumers::State.current! }

wait_for = lambda do |description, &condition|
  Timeout.timeout(120) { sleep(0.5) until condition.call }
rescue Timeout::Error
  puts File.read(log)

  assert(false, "Timed out waiting for #{description}")
end

first_pid = start_server.call

wait_for.call("the first state flush") { !current_state.call[:processes].empty? }

# These reports are aggregated but not marked as consumed before the shutdown
10.times { |i| Karafka.producer.produce_sync(topic: TOPIC, payload: i.to_s) }
sleep(5)

stop_server.call(first_pid)

stopped_state = current_state.call
stopped_offset = stopped_state[:processes].values.map { |process| process[:offset] }.max

committed = Karafka::Admin
  .read_lags_with_offsets({ Karafka::Web.config.group_id => [reports_topic] })
  .dig(Karafka::Web.config.group_id, reports_topic, 0, :offset)

assert(committed <= stopped_offset, "The restarted server should consume reports again")

second_pid = start_server.call

wait_for.call("the state flush of the restarted server") do
  (current_state.call[:processes].keys - stopped_state[:processes].keys).any?
end

stop_server.call(second_pid)

restarted_state = current_state.call
restarted_offset = restarted_state[:processes].values.map { |process| process[:offset] }.max

new_reports = Karafka::Admin
  .read_topic(reports_topic, 0, restarted_offset - stopped_offset, stopped_offset + 1)
  .map { |message| JSON.parse(Zlib::Inflate.inflate(message.raw_payload), symbolize_names: true) }

expected = stopped_state[:stats][:messages] +
  new_reports.sum { |report| report[:stats][:total][:messages] }

assert_equal(
  expected,
  restarted_state[:stats][:messages],
  "Replayed reports should not be counted again"
)

puts "State replay after restart: OK"
