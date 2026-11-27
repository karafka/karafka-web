# frozen_string_literal: true

# Verifies that a `karafka server` with busy workers reports their utilization through the Web UI
# consumers reports.
#
# Needs Kafka at `KAFKA_BOOTSTRAP_SERVERS` (default: 127.0.0.1:9092).

require "bundler/setup"
require "json"
require "open3"
require "securerandom"
require "tmpdir"
require_relative "helper"

include IntegrationHelper

# How long the server runs, in seconds. Covers a few tracking intervals after it joins the group.
RUN_TIME = 25

dir = Dir.mktmpdir
boot_file = File.join(dir, "karafka.rb")
# Every process loads the boot file, so the random names are fixed here
suffix = SecureRandom.hex(6)

File.write(boot_file, <<~RUBY)
  # frozen_string_literal: true

  require "karafka"
  require "karafka/web"

  TOPIC = "it-worker-utilization-#{suffix}"

  class KarafkaApp < Karafka::App
    setup do |config|
      config.kafka = {
        "bootstrap.servers": ENV.fetch("KAFKA_BOOTSTRAP_SERVERS", "127.0.0.1:9092")
      }
      config.client_id = "it-worker-utilization-#{suffix}"
      config.concurrency = 1
      config.max_messages = 1
      config.shutdown_timeout = 10_000
    end

    routes.draw do
      topic TOPIC do
        consumer Class.new(Karafka::BaseConsumer) { def consume = sleep(0.05) }
      end
    end
  end

  Karafka::Web.setup do |config|
    config.ui.sessions.secret = "#{SecureRandom.hex(64)}"
    config.group_id = "it-worker-utilization-web-#{suffix}"
    config.topics.errors.name = "it-worker-utilization-errors-#{suffix}"
    config.topics.consumers.reports.name = "it-worker-utilization-reports-#{suffix}"
    config.topics.consumers.states.name = "it-worker-utilization-states-#{suffix}"
    config.topics.consumers.metrics.name = "it-worker-utilization-metrics-#{suffix}"
    config.topics.consumers.commands.name = "it-worker-utilization-commands-#{suffix}"
  end

  Karafka::Web.enable!
RUBY

env = { "KARAFKA_BOOT_FILE" => boot_file }

# More work than the server can do in RUN_TIME, so its worker never idles
setup_script = <<~RUBY
  require ENV.fetch("KARAFKA_BOOT_FILE")
  Karafka::Web::Installer.new.install
  Karafka::Admin.create_topic(TOPIC, 1, 1)
  Karafka.producer.produce_many_sync(Array.new(2_000) { { topic: TOPIC, payload: "{}" } })
RUBY

# Kafka may still be starting when this scenario runs in its own container
setup_out = nil
set_up = 30.times.any? do
  setup_out, status = Open3.capture2e(env, "bundle", "exec", "ruby", "-e", setup_script)
  next true if status.success?

  sleep(2)
  false
end

puts setup_out unless set_up

assert(set_up, "Web UI install and topic setup should succeed")

server_log = File.join(dir, "server.log")
pid = Process.spawn(env, "bundle", "exec", "karafka", "server", out: server_log, err: server_log)
sleep(RUN_TIME)
Process.kill("TERM", pid)
Process.wait(pid)

reports_out, status = Open3.capture2e(
  env,
  "bundle", "exec", "ruby", "-e",
  <<~RUBY
    require ENV.fetch("KARAFKA_BOOT_FILE")
    reports = Karafka::Web.config.topics.consumers.reports.name
    deserializer = Karafka::Web::Deserializer.new
    puts Karafka::Admin.read_topic(reports, 0, 100).map { |message| deserializer.call(message) }.to_json
  RUBY
)

assert(status.success?, "Reading the consumers reports should succeed: #{reports_out}")

running = JSON.parse(reports_out.lines.last, symbolize_names: true)
  .select { |report| report[:process][:status] == "running" }

if running.empty?
  puts File.read(server_log)

  assert(false, "The server should report while running")
end

utilization = running.last[:stats][:utilization]

# The worker is busy from the group join until the end, minus boot and rebalance time
assert_in_range(utilization, 30, 100, "The busy worker utilization should be reported")

puts "Worker utilization (#{utilization}%): OK"
