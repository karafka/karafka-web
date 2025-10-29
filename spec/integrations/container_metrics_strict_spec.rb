# frozen_string_literal: true

require 'bundler/setup'
require 'karafka/web'
require_relative 'helper'

include IntegrationHelper

puts '\n=== Container Metrics (256MB limit) ==='

shell = Karafka::Web::Tracking::MemoizedShell.new
container_metrics = Karafka::Web::Tracking::Consumers::Sampler::Metrics::Container.new(shell)

memory_limit = Karafka::Web::Tracking::Consumers::Sampler::Metrics::Container.memory_limit
assert(memory_limit, 'Should detect memory limit')
assert_in_range(memory_limit, 252_000, 272_000, 'Memory limit should be ~256MB')

memory_size = container_metrics.memory_size
assert(memory_size < 300_000, 'Memory size should be less than 300MB')
assert(memory_size > 200_000, 'Memory size should be more than 200MB')

memory_usage = container_metrics.memory_usage
assert(memory_usage > 0, 'Memory usage should be positive')

cpus = container_metrics.cpus
assert(cpus > 0, 'CPU count should be positive')

puts 'All tests passed'
