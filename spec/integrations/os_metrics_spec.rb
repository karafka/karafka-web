# frozen_string_literal: true

require "bundler/setup"
require "karafka/web"
require_relative "helper"

include IntegrationHelper

shell = Karafka::Web::Tracking::MemoizedShell.new
os_metrics = Karafka::Web::Tracking::Consumers::Sampler::Metrics::Os.new(shell)

memory_size = os_metrics.memory_size
assert(memory_size > 0, "Memory size should be positive")
assert_type(memory_size, Integer, "Memory size should be an integer")

memory_usage = os_metrics.memory_usage
assert(memory_usage > 0, "Memory usage should be positive")
assert_type(memory_usage, Integer, "Memory usage should be an integer")
assert(memory_usage < memory_size, "Process memory should be less than total memory")

cpus = os_metrics.cpus
assert(cpus > 0, "CPU count should be positive")
assert_type(cpus, Integer, "CPU count should be an integer")

cpu_usage = os_metrics.cpu_usage
assert_type(cpu_usage, Array, "CPU usage should be an array")
assert(cpu_usage.length == 3, "CPU usage should return 3 load averages")
cpu_usage.each_with_index do |load, i|
  assert_type(load, Float, "Load average #{i} should be a float")
  assert(load >= 0, "Load average #{i} should be non-negative")
end

memory_threads_ps = os_metrics.memory_threads_ps
if memory_threads_ps
  assert_type(memory_threads_ps, Array, "memory_threads_ps should be an array")
  assert(memory_threads_ps.any?, "memory_threads_ps should not be empty")

  sample = memory_threads_ps.first
  assert(sample.is_a?(Array), "Each entry should be an array")
  assert(sample.length == 3, "Each entry should have 3 elements")

  memory_total = os_metrics.memory_total_usage(memory_threads_ps)
  assert(memory_total > 0, "Total memory usage should be positive")
  assert_type(memory_total, Integer, "Total memory usage should be an integer")
  assert(memory_total >= memory_usage, "Total memory should be >= process memory")

  threads = os_metrics.threads(memory_threads_ps)
  assert(threads >= 0, "Thread count should be non-negative")
  assert_type(threads, Integer, "Thread count should be an integer")
end
