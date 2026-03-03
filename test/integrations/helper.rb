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

  # Asserts that a comparison operator holds between two values
  #
  # @param value1 [Object] the left-hand side value
  # @param operator [Symbol] the comparison operator (e.g., :<, :>, :<=, :>=)
  # @param value2 [Object] the right-hand side value
  # @param message [String] error message to display if assertion fails
  def assert_operator(value1, operator, value2, message)
    return if value1.public_send(operator, value2)

    puts <<~ERROR
      FAILED: #{message}
        Expected: #{value1} #{operator} #{value2}
    ERROR
    exit 1
  end

  # Asserts that an object responds to a predicate method with true
  #
  # @param object [Object] the object to test
  # @param predicate [Symbol] the predicate method to call (e.g., :any?, :empty?)
  # @param message [String] error message to display if assertion fails
  def assert_predicate(object, predicate, message)
    return if object.public_send(predicate)

    puts <<~ERROR
      FAILED: #{message}
        Expected #{object.inspect} to respond truthy to #{predicate}
    ERROR
    exit 1
  end

  # Asserts that a value is an instance of a class or its subclass
  #
  # @param klass [Class] the expected class
  # @param object [Object] the object to check
  # @param message [String] error message to display if assertion fails
  def assert_kind_of(klass, object, message)
    return if object.is_a?(klass)

    puts <<~ERROR
      FAILED: #{message}
        Expected kind of: #{klass}
        Got: #{object.class}
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
