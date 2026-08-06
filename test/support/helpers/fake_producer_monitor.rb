# frozen_string_literal: true

# Minimal stand-in for a producer monitor. It records subscriptions and reflects them through
# `#listeners` the same way a real monitor does, so producer listener subscription idempotency
# ("subscribed at most once") can be asserted against actual state rather than mock call counts.
class FakeProducerMonitor
  attr_reader :listeners

  def initialize
    @listeners = Hash.new { |hash, key| hash[key] = [] }
  end

  def subscribe(listener)
    @listeners["error.occurred"] << listener
  end

  # @param listener [Object] listener to count
  # @return [Integer] how many times the listener is subscribed across all events
  def subscribed_count(listener)
    @listeners.each_value.sum { |event_listeners| event_listeners.count(listener) }
  end
end
