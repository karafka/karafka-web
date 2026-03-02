# frozen_string_literal: true

# Common helper methods for integration tests
# Provides assertion utilities for plain Ruby test scripts
module IntegrationHelper
  # Asserts that a condition is true, exits with error if false
  #
  # @param condition [Boolean] the condition to check
  # @param message [String] error message to display if assertion fails
  def assert(condition, message)
    return if condition

    puts "FAILED: #{message}"
    exit 1
  end

  # Asserts that two values are equal, exits with error if not
  #
  # @param expected [Object] the expected value
  # @param actual [Object] the actual value
  # @param message [String] error message to display if assertion fails
  def assert_equal(expected, actual, message)
    return if expected == actual

    puts <<~ERROR
      FAILED: #{message}
        Expected: #{expected}
        Got: #{actual}
    ERROR
    exit 1
  end

  # Asserts that a value is of a specific type, exits with error if not
  #
  # @param value [Object] the value to check
  # @param type [Class] the expected type
  # @param message [String] error message to display if assertion fails
  def assert_type(value, type, message)
    return if value.is_a?(type)

    puts <<~ERROR
      FAILED: #{message}
        Expected type: #{type}
        Got: #{value.class}
    ERROR
    exit 1
  end

  # Asserts that a value is within a range, exits with error if not
  #
  # @param value [Numeric] the value to check
  # @param min [Numeric] minimum value (inclusive)
  # @param max [Numeric] maximum value (inclusive)
  # @param message [String] error message to display if assertion fails
  def assert_in_range(value, min, max, message)
    return if value.between?(min, max)

    puts <<~ERROR
      FAILED: #{message}
        Expected: between #{min} and #{max}
        Got: #{value}
    ERROR
    exit 1
  end
end
