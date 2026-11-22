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

$stderr = StringIO.new

Karafka::Web.setup do |config|
  config.ui.sessions.secret = SecureRandom.hex(64)
  config.ui.dlq_patterns << /legacy_errors/
end

assert_equal(
  [/(dlq)|(dead_letter)/i, /legacy_errors/],
  Karafka::Web.config.ui.dead_letter_queue_patterns,
  "dlq_patterns << should extend dead_letter_queue_patterns"
)

Karafka::Web.setup do |config|
  config.ui.dlq_patterns = [/legacy_only/]
end

assert_equal(
  [/legacy_only/],
  Karafka::Web.config.ui.dead_letter_queue_patterns,
  "dlq_patterns= should set dead_letter_queue_patterns"
)

assert_equal(
  [/legacy_only/],
  Karafka::Web.config.to_h[:ui][:dead_letter_queue_patterns],
  "The validated config should hold the patterns set through dlq_patterns"
)

Karafka::Web::Contracts::Config.new.validate!(Karafka::Web.config.to_h)

warnings = $stderr.string
$stderr = STDERR

read_warned = warnings.include?("config.ui.dlq_patterns is deprecated")

assert(read_warned, "Reading dlq_patterns should warn that it is deprecated")

write_warned = warnings.include?("config.ui.dlq_patterns= is deprecated")

assert(write_warned, "Setting dlq_patterns should warn that it is deprecated")

$stderr = StringIO.new

Karafka::Web.setup do |config|
  config.ui.dead_letter_queue_patterns = [/current/]
  config.ui.dead_letter_queue_patterns << /current_extra/
end

warnings = $stderr.string
$stderr = STDERR

assert_equal("", warnings, "The new name should not warn")

$stderr = StringIO.new
Karafka::Web.config.ui.dlq_patterns = "not-an-array"
$stderr = STDERR

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
