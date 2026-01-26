# frozen_string_literal: true

require "bundler/setup"
require "karafka/web"
require_relative "helper"

include IntegrationHelper

shell = Karafka::Web::Tracking::MemoizedShell.new
container_metrics = Karafka::Web::Tracking::Consumers::Sampler::Metrics::Container.new(shell)

active = Karafka::Web::Tracking::Consumers::Sampler::Metrics::Container.active?
assert(active, "Should detect containerized environment")

has_v2 = File.exist?("/sys/fs/cgroup/cgroup.controllers")
has_v1 = File.exist?("/sys/fs/cgroup/memory/memory.limit_in_bytes")
assert(has_v2 || has_v1, "Should find cgroup v1 or v2 files")

memory_limit = Karafka::Web::Tracking::Consumers::Sampler::Metrics::Container.memory_limit
assert(memory_limit, "Should detect memory limit")
assert_in_range(memory_limit, 514_000, 534_000, "Memory limit should be ~512MB")

memory_size = container_metrics.memory_size
assert(memory_size < 600_000, "Should use container limit, not host memory")
assert(memory_size > 400_000, "Memory size should be more than 400MB")

memory_usage = container_metrics.memory_usage
assert(memory_usage > 0, "Memory usage should be positive")
assert_type(memory_usage, Integer, "Memory usage should be an integer")

cpus = container_metrics.cpus
assert(cpus > 0, "CPU count should be positive")
assert_type(cpus, Integer, "CPU count should be an integer")

memory_threads_ps = container_metrics.memory_threads_ps
assert(memory_threads_ps, "Should get process data")
assert_type(memory_threads_ps, Array, "Process data should be an array")

memory_total = container_metrics.memory_total_usage(memory_threads_ps)
assert(memory_total > 0, "Total memory usage should be positive")

threads = container_metrics.threads(memory_threads_ps)
assert(threads > 0, "Thread count should be positive")
