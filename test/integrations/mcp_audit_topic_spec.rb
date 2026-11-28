# frozen_string_literal: true

# Verifies that the Web UI install creates the MCP audit topic with its configured name, the
# `delete` cleanup policy and the long default retention, next to the other Web UI topics.
#
# Needs Kafka at `KAFKA_BOOTSTRAP_SERVERS` (default: 127.0.0.1:9092).

require "bundler/setup"
require "open3"
require "securerandom"
require "tmpdir"
require_relative "helper"

include IntegrationHelper

dir = Dir.mktmpdir
boot_file = File.join(dir, "karafka.rb")
suffix = SecureRandom.hex(6)
audit_topic = "it-mcp-audit-#{suffix}"

File.write(boot_file, <<~RUBY)
  # frozen_string_literal: true

  require "karafka"
  require "karafka/web"

  class KarafkaApp < Karafka::App
    setup do |config|
      config.kafka = { "bootstrap.servers": ENV.fetch("KAFKA_BOOTSTRAP_SERVERS", "127.0.0.1:9092") }
      config.client_id = "it-mcp-audit-#{suffix}"
    end
  end

  Karafka::Web.setup do |config|
    config.ui.sessions.secret = "#{SecureRandom.hex(64)}"
    config.group_id = "it-mcp-audit-web-#{suffix}"
    config.topics.errors.name = "it-mcp-audit-errors-#{suffix}"
    config.topics.consumers.reports.name = "it-mcp-audit-reports-#{suffix}"
    config.topics.consumers.states.name = "it-mcp-audit-states-#{suffix}"
    config.topics.consumers.metrics.name = "it-mcp-audit-metrics-#{suffix}"
    config.topics.consumers.commands.name = "it-mcp-audit-commands-#{suffix}"
    config.topics.mcp_audit.name = "#{audit_topic}"
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
assert_includes(install_out, audit_topic, "Install should report the MCP audit topic")

configs_out, status = Open3.capture2e(
  env,
  "bundle", "exec", "ruby", "-e",
  <<~RUBY
    require ENV.fetch("KARAFKA_BOOT_FILE")

    resource = Karafka::Admin::Configs::Resource.new(type: :topic, name: "#{audit_topic}")
    configs = Karafka::Admin::Configs.describe(resource).first.configs

    %w[cleanup.policy retention.ms].each do |name|
      puts "\#{name}=\#{configs.find { |config| config.name == name }.value}"
    end
  RUBY
)

puts configs_out unless status.success?

assert(status.success?, "The MCP audit topic configs should be readable")
assert_includes(configs_out, "cleanup.policy=delete", "The MCP audit topic should use delete")
assert_includes(
  configs_out, "retention.ms=#{365 * 24 * 60 * 60 * 1_000}",
  "The MCP audit topic should keep records for a year"
)

puts "MCP audit topic integration test passed"
