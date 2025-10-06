# frozen_string_literal: true

require 'bundler/setup'
require 'karafka/web'
require_relative 'helper'

include IntegrationHelper

puts '\n=== Container Metrics (unlimited) ==='

shell = Karafka::Web::Tracking::MemoizedShell.new
container_metrics = Karafka::Web::Tracking::Consumers::Sampler::Metrics::Container.new(shell)

active = Karafka::Web::Tracking::Consumers::Sampler::Metrics::Container.active?
assert(active, 'Should detect containerized environment')

memory_limit = Karafka::Web::Tracking::Consumers::Sampler::Metrics::Container.memory_limit
if !memory_limit.nil? && memory_limit < 100_000_000
  puts "FAILED: Expected no limit, got #{memory_limit} KB"
  exit 1
end

memory_size = container_metrics.memory_size
assert(memory_size > 2_000_000, 'Should use host memory when no container limit')

memory_usage = container_metrics.memory_usage
assert(memory_usage > 0, 'Memory usage should be positive')

cpus = container_metrics.cpus
assert(cpus > 0, 'CPU count should be positive')

puts 'All tests passed'
