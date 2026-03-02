# frozen_string_literal: true

# Module-based factories replacing FactoryBot
# Provides a `build` method that delegates to factory modules
module Factories
  # Builds a factory object by name
  # @param factory_name [Symbol] the factory to build
  # @param kwargs [Hash] attributes to override
  # @return [Object] the built object
  def build(factory_name, **kwargs)
    case factory_name
    when :consumer
      Factories::Consumer.build(**kwargs)
    when :routing_topic
      Factories::Routing.build_topic(**kwargs)
    when :routing_consumer_group
      Factories::Routing.build_consumer_group(**kwargs)
    when :routing_subscription_group
      Factories::Routing.build_subscription_group(**kwargs)
    when :processing_coordinator
      Factories::Processing.build_coordinator(**kwargs)
    when :time_trackers_pause
      Factories::TimeTrackers.build_pause(**kwargs)
    else
      raise ArgumentError, "Unknown factory: #{factory_name}"
    end
  end
end
