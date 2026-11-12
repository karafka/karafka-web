# frozen_string_literal: true

# Verifies that `Karafka::Web.enable!` logs one warning when the Web UI reports through an
# idempotent or transactional app producer, and none when it reports through a non-idempotent
# one or a custom Web UI producer is configured.
#
# Each case runs in its own process because the Web UI can be enabled only once per process.

require "bundler/setup"
require "open3"
require "securerandom"
require "tmpdir"
require_relative "helper"

include IntegrationHelper

WARNING = "Unable to reconstruct MessageSet"

APP = <<~RUBY
  require "karafka"
  require "karafka/web"
  require "logger"

  app_kafka = { "bootstrap.servers": "127.0.0.1:9092" }
  app_kafka[:"enable.idempotence"] = true if ENV["APP_PRODUCER"] == "idempotent"
  app_kafka[:"transactional.id"] = SecureRandom.uuid if ENV["APP_PRODUCER"] == "transactional"

  class KarafkaApp < Karafka::App; end

  KarafkaApp.setup do |config|
    config.kafka = { "bootstrap.servers": "127.0.0.1:9092" }
    config.client_id = SecureRandom.hex(6)
    config.logger = Logger.new(ENV.fetch("LOG_FILE"))
    config.producer = WaterDrop::Producer.new { |p_config| p_config.kafka = app_kafka }
  end

  Karafka::Web.setup do |config|
    config.ui.sessions.secret = SecureRandom.hex(64)

    if ENV["WEB_PRODUCER"] == "custom"
      config.producer = WaterDrop::Producer.new do |p_config|
        p_config.kafka = { "bootstrap.servers": "127.0.0.1:9092" }
      end
    end
  end

  Karafka::Web.enable!
  Karafka::Web.enable!
RUBY

# @param app_producer [String] kind of the app producer
# @param web_producer [String] `default` or `custom`
# @return [Integer] number of the shared producer warnings logged
def warnings_count(app_producer, web_producer)
  log_file = File.join(Dir.mktmpdir, "karafka.log")
  env = { "APP_PRODUCER" => app_producer, "WEB_PRODUCER" => web_producer, "LOG_FILE" => log_file }

  out, status = Open3.capture2e(env, "bundle", "exec", "ruby", "-rsecurerandom", "-e", APP)

  assert(status.success?, "The app should enable the Web UI (#{app_producer}): #{out}")

  File.read(log_file).lines.count { |line| line.include?("WARN") && line.include?(WARNING) }
end

assert_equal(1, warnings_count("idempotent", "default"), "Idempotent app producer should warn")
assert_equal(1, warnings_count("transactional", "default"), "Transactional app producer should warn")
assert_equal(0, warnings_count("regular", "default"), "Regular app producer should not warn")
assert_equal(0, warnings_count("idempotent", "custom"), "Custom Web UI producer should not warn")
assert_equal(0, warnings_count("transactional", "custom"), "Custom Web UI producer should not warn")

puts "Shared producer warning: OK"
