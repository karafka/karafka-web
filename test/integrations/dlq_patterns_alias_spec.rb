# frozen_string_literal: true

# Verifies that a Web UI setup using the former `config.ui.dlq_patterns` name still configures
# the dead letter queue auto-discovery patterns, passes the config validation and warns that the
# name is deprecated.

require "bundler/setup"
require "karafka/web"
require "securerandom"
require "stringio"
require_relative "helper"

include IntegrationHelper

# @return [String] what the block wrote to stderr
def capture_stderr
  original = $stderr
  $stderr = StringIO.new
  yield
  $stderr.string
ensure
  $stderr = original
end

Karafka::Web.setup do |config|
  config.ui.sessions.secret = SecureRandom.hex(64)
end

warnings = capture_stderr { Karafka::Web.config.ui.dlq_patterns << /legacy_errors/ }

assert_equal(
  [/(dlq)|(dead_letter)/i, /legacy_errors/],
  Karafka::Web.config.ui.dead_letter_queue_patterns,
  "dlq_patterns << should extend dead_letter_queue_patterns"
)

read_warned = warnings.include?("config.ui.dlq_patterns is deprecated")

assert(read_warned, "Reading dlq_patterns should warn that it is deprecated")

warnings = capture_stderr { Karafka::Web.config.ui.dlq_patterns = [/legacy_only/] }

assert_equal(
  [/legacy_only/],
  Karafka::Web.config.ui.dead_letter_queue_patterns,
  "dlq_patterns= should set dead_letter_queue_patterns"
)

write_warned = warnings.include?("config.ui.dlq_patterns= is deprecated")

assert(write_warned, "Setting dlq_patterns should warn that it is deprecated")

assert_equal(
  [/legacy_only/],
  Karafka::Web.config.to_h[:ui][:dead_letter_queue_patterns],
  "The validated config should hold the patterns set through dlq_patterns"
)

Karafka::Web::Contracts::Config.new.validate!(Karafka::Web.config.to_h)

warnings = capture_stderr do
  Karafka::Web.config.ui.dead_letter_queue_patterns = [/current/]
  Karafka::Web.config.ui.dead_letter_queue_patterns << /current_extra/
end

assert_equal("", warnings, "The new name should not warn")

capture_stderr { Karafka::Web.config.ui.dlq_patterns = "not-an-array" }

error = begin
  Karafka::Web::Contracts::Config.new.validate!(Karafka::Web.config.to_h)
  nil
rescue Karafka::Web::Errors::ContractError => e
  e
end

assert(error, "Invalid patterns set through dlq_patterns should fail the validation")

named = error.message.include?("ui.dead_letter_queue_patterns")

assert(named, "The validation error should name the new setting")

puts "DLQ patterns alias: OK"
