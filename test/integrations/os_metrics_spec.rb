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
assert_equal(3, cpu_usage.length, "CPU usage should return 3 load averages")
cpu_usage.each_with_index do |load, i|
  assert_type(load, Float, "Load average #{i} should be a float")
  assert(load >= 0, "Load average #{i} should be non-negative")
end

memory_usage_before = os_metrics.memory_usage
memory_threads_ps = os_metrics.memory_threads_ps
memory_usage_after = os_metrics.memory_usage

if memory_threads_ps
  assert_type(memory_threads_ps, Array, "memory_threads_ps should be an array")
  assert(memory_threads_ps.any?, "memory_threads_ps should not be empty")
  sample = memory_threads_ps.first

  assert_kind_of(Array, sample, "Each entry should be an array")
  assert_equal(3, sample.length, "Each entry should have 3 elements")

  memory_total = os_metrics.memory_total_usage(memory_threads_ps)

  assert(memory_total > 0, "Total memory usage should be positive")
  assert_type(memory_total, Integer, "Total memory usage should be an integer")

  current_process = memory_threads_ps.find { |row| row.last == Process.pid }

  assert(current_process, "memory_threads_ps should include the current process")
  assert(current_process.first > 0, "Current process memory should be positive")

  # statm and VmRSS cannot be read at the same moment and RSS moves between reads (JRuby GC),
  # so the statm value is checked against the VmRSS reads around it with a 10% slack
  min_rss, max_rss = [memory_usage_before, memory_usage_after].minmax
  min_rss = (min_rss * 0.9).floor
  max_rss = (max_rss * 1.1).ceil

  assert(
    current_process.first.between?(min_rss, max_rss),
    "Process memory from statm (#{current_process.first}) should be within " \
    "#{min_rss}..#{max_rss} of VmRSS"
  )
  assert(memory_total >= min_rss, "Total memory should be >= process memory")

  threads = os_metrics.threads(memory_threads_ps)

  assert(threads >= 0, "Thread count should be non-negative")
  assert_type(threads, Integer, "Thread count should be an integer")
end
