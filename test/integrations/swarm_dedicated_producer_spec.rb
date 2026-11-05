# frozen_string_literal: true

# Verifies that under `karafka swarm` every node keeps the dedicated, non-idempotent Web UI
# producer the user configured, instead of switching to the (idempotent) app producer, and that
# this producer can deliver from within the node.
#
# Needs Kafka at `KAFKA_BOOTSTRAP_SERVERS` (default: 127.0.0.1:9092).

require "bundler/setup"
require "json"
require "open3"
require "securerandom"
require "tmpdir"
require "timeout"
require_relative "helper"

include IntegrationHelper

NODES = 2

dir = Dir.mktmpdir
results_dir = File.join(dir, "results")
Dir.mkdir(results_dir)
boot_file = File.join(dir, "karafka.rb")

File.write(boot_file, <<~RUBY)
  # frozen_string_literal: true

  require "karafka"
  require "karafka/web"

  BOOTSTRAP_SERVERS = ENV.fetch("KAFKA_BOOTSTRAP_SERVERS", "127.0.0.1:9092")
  RESULTS_DIR = #{results_dir.inspect}
  TOPIC = "it-swarm-web-producer-#{SecureRandom.hex(6)}"

  class KarafkaApp < Karafka::App
    setup do |config|
      config.kafka = { "bootstrap.servers": BOOTSTRAP_SERVERS }
      config.client_id = "it-swarm-web-producer"
      config.swarm.nodes = #{NODES}
      config.shutdown_timeout = 10_000

      config.producer = WaterDrop::Producer.new do |p_config|
        p_config.kafka = {
          "bootstrap.servers": BOOTSTRAP_SERVERS,
          "enable.idempotence": true
        }
      end
    end

    routes.draw do
      topic TOPIC do
        config(partitions: #{NODES})
        consumer Class.new(Karafka::BaseConsumer) { def consume; end }
      end
    end
  end

  WEB_PRODUCER = WaterDrop::Producer.new do |p_config|
    p_config.kafka = {
      "bootstrap.servers": BOOTSTRAP_SERVERS,
      "enable.idempotence": false
    }
  end

  Karafka::Web.setup do |config|
    config.ui.sessions.secret = "#{SecureRandom.hex(64)}"
    config.producer = WEB_PRODUCER
  end

  Karafka::Web.enable!

  Karafka.monitor.subscribe("app.running") do
    web_producer = Karafka::Web.producer
    report = web_producer.produce_sync(topic: TOPIC, payload: "web")

    File.write(
      File.join(RESULTS_DIR, Process.pid.to_s),
      {
        dedicated: web_producer.equal?(WEB_PRODUCER),
        web_non_idempotent: !web_producer.idempotent?,
        app_idempotent: Karafka.producer.idempotent?,
        delivered: report.error.nil? && !report.offset.negative?
      }.to_json
    )
  end
RUBY

env = { "KARAFKA_BOOT_FILE" => boot_file }

# Kafka may still be starting when this scenario runs in its own container
install_out = nil
installed = 30.times.any? do
  install_out, status = Open3.capture2e(
    env,
    "bundle", "exec", "ruby", "-e",
    'require ENV.fetch("KARAFKA_BOOT_FILE"); Karafka::Web::Installer.new.install'
  )
  next true if status.success?

  sleep(2)
  false
end

puts install_out unless installed

assert(installed, "Web UI install should succeed")

swarm_log = File.join(dir, "swarm.log")
pid = Process.spawn(env, "bundle", "exec", "karafka", "swarm", out: swarm_log, err: swarm_log)

begin
  Timeout.timeout(120) do
    sleep(0.5) until Dir.children(results_dir).size >= NODES
  end
rescue Timeout::Error
  puts File.read(swarm_log)

  assert(false, "Every swarm node should report its Web UI producer")
ensure
  Process.kill("TERM", pid)
  Process.wait(pid)
end

reports = Dir.children(results_dir).map do |node_pid|
  JSON.parse(File.read(File.join(results_dir, node_pid)), symbolize_names: true)
end

assert_equal(NODES, reports.size, "Every swarm node should report")

reports.each do |report|
  assert(report[:app_idempotent], "The node app producer should stay idempotent")
  assert(report[:dedicated], "The node should keep the dedicated Web UI producer")
  assert(report[:web_non_idempotent], "The node Web UI producer should not be idempotent")
  assert(report[:delivered], "The dedicated Web UI producer should deliver from the node")
end

puts "Swarm dedicated Web UI producer: OK"
