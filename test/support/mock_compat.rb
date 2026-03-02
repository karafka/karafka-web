# frozen_string_literal: true

# Lightweight mock compatibility layer providing RSpec-like mocking API on top of
# simple method stubbing. This allows tests migrated from RSpec to keep their
# existing mock/stub patterns without a full rewrite.
#
# Supported patterns:
#   allow(obj).to receive(:method).and_return(value)
#   allow(obj).to receive(:method).and_call_original
#   allow(obj).to receive(:method).and_raise(error)
#   allow(obj).to receive(:method).and_yield(value)
#   allow(obj).to receive(:method) { |args| block }
#   allow(obj).to receive_messages(method1: val1, method2: val2)
#   expect(obj).to have_received(:method)
#   expect(obj).to have_received(:method).with(args)
#   expect(obj).to have_received(:method).once
#   expect(obj).not_to have_received(:method)
#   instance_double(ClassName, method1: val1, ...)
module MockCompat
  # Registry of all stubs applied during a test, for cleanup
  STUB_REGISTRY = []
  # Registry of method call recordings
  CALL_REGISTRY = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }

  # Clean up all stubs and call recordings after each test
  def self.cleanup!
    STUB_REGISTRY.each do |obj, method_name, original|
      if original == :__mock_compat_no_original__
        # Remove the method we added
        if obj.respond_to?(method_name)
          obj.singleton_class.remove_method(method_name) rescue nil
        end
      else
        obj.define_singleton_method(method_name, original)
      end
    end
    STUB_REGISTRY.clear
    CALL_REGISTRY.clear
  end

  # Provides allow(obj) syntax
  def allow(obj)
    AllowProxy.new(obj)
  end

  # Creates a simple test double that responds to specified methods
  def instance_double(_klass, stubs = {})
    mock = Object.new
    stubs.each do |method_name, return_value|
      mock.define_singleton_method(method_name) { |*_args, **_kwargs, &_block| return_value }
    end
    mock
  end

  # Returns a matcher for have_received assertions
  def have_received(method_name)
    HaveReceivedMatcher.new(method_name)
  end

  # Returns a receive matcher for setting up stubs
  def receive(method_name)
    ReceiveMatcher.new(method_name)
  end

  # Returns a receive_messages matcher for setting up multiple stubs
  def receive_messages(hash)
    ReceiveMessagesMatcher.new(hash)
  end

  # Returns a matcher that checks if a hash includes certain keys
  def hash_including(**expected)
    HashIncludingMatcher.new(expected)
  end

  # Proxy for allow(obj).to receive(...)
  class AllowProxy
    def initialize(obj)
      @obj = obj
    end

    def to(matcher)
      case matcher
      when ReceiveMatcher
        matcher.apply(@obj)
      when ReceiveMessagesMatcher
        matcher.apply(@obj)
      end
    end
  end

  # Matcher for receive(:method).and_return(value) chains
  class ReceiveMatcher
    attr_reader :method_name

    def initialize(method_name)
      @method_name = method_name
      @return_value = nil
      @return_block = nil
      @call_original = false
      @raise_error = nil
      @yield_value = nil
    end

    def and_return(*values)
      if values.length == 1
        @return_value = values.first
      else
        @return_values = values
      end
      self
    end

    def and_call_original
      @call_original = true
      self
    end

    def and_raise(*args)
      @raise_error = args
      self
    end

    def and_yield(*values)
      @yield_value = values
      self
    end

    def apply(obj)
      method_name = @method_name
      return_value = @return_value
      return_values = @return_values
      call_original = @call_original
      raise_error = @raise_error
      yield_value = @yield_value

      # Save original method if it exists
      original = if obj.respond_to?(method_name)
        obj.method(method_name)
      else
        :__mock_compat_no_original__
      end

      call_count = [0]

      obj.define_singleton_method(method_name) do |*args, **kwargs, &block|
        # Record the call
        MockCompat::CALL_REGISTRY[obj.__id__][method_name] << {
          args: args,
          kwargs: kwargs,
          block: block
        }

        if raise_error
          raise(*raise_error)
        elsif yield_value
          block&.call(*yield_value)
        elsif call_original && original != :__mock_compat_no_original__
          original.call(*args, **kwargs, &block)
        elsif return_values
          idx = [call_count[0], return_values.length - 1].min
          call_count[0] += 1
          return_values[idx]
        else
          return_value
        end
      end

      MockCompat::STUB_REGISTRY << [obj, method_name, original]
    end
  end

  # Matcher for receive_messages(method1: val1, method2: val2)
  class ReceiveMessagesMatcher
    def initialize(hash)
      @hash = hash
    end

    def apply(obj)
      @hash.each do |method_name, return_value|
        matcher = ReceiveMatcher.new(method_name)
        matcher.and_return(return_value)
        matcher.apply(obj)
      end
    end
  end

  # Matcher for expect(obj).to have_received(:method)
  class HaveReceivedMatcher
    def initialize(method_name)
      @method_name = method_name
      @expected_args = nil
      @expected_kwargs = nil
      @count = nil
    end

    def with(*args, **kwargs)
      @expected_args = args
      @expected_kwargs = kwargs.empty? ? nil : kwargs
      self
    end

    def once
      @count = 1
      self
    end

    def twice
      @count = 2
      self
    end

    def exactly(n)
      ExactlyProxy.new(self, n)
    end

    def set_count(n)
      @count = n
    end

    def matches?(obj)
      calls = MockCompat::CALL_REGISTRY[obj.__id__][@method_name]

      if @expected_args || @expected_kwargs
        calls = calls.select do |call|
          args_match = @expected_args.nil? || args_match?(@expected_args, call[:args])
          kwargs_match = @expected_kwargs.nil? || kwargs_match?(@expected_kwargs, call[:kwargs])
          args_match && kwargs_match
        end
      end

      if @count
        calls.length == @count
      else
        calls.length > 0
      end
    end

    def failure_message(obj)
      calls = MockCompat::CALL_REGISTRY[obj.__id__][@method_name]
      "Expected #{obj.class}##{@method_name} to have been called" \
        "#{@count ? " #{@count} time(s)" : ""}" \
        "#{@expected_args ? " with #{@expected_args.inspect}" : ""}" \
        ", but was called #{calls.length} time(s)"
    end

    def negative_failure_message(obj)
      "Expected #{obj.class}##{@method_name} not to have been called, but it was"
    end

    # Supports have_received(:m) do |arg| ... end
    def call_args(obj)
      calls = MockCompat::CALL_REGISTRY[obj.__id__][@method_name]
      calls.last
    end

    private

    def args_match?(expected, actual)
      return true if expected.nil?
      return true if expected.length == 1 && expected.first.is_a?(HashIncludingMatcher)

      expected.each_with_index.all? do |exp, i|
        if exp.is_a?(HashIncludingMatcher)
          exp.matches?(actual[i])
        else
          exp == actual[i]
        end
      end
    end

    def kwargs_match?(expected, actual)
      return true if expected.nil?

      expected.all? { |k, v| actual[k] == v }
    end
  end

  class ExactlyProxy
    def initialize(matcher, n)
      @matcher = matcher
      @n = n
    end

    def times
      @matcher.set_count(@n)
      @matcher
    end
  end

  # Hash matcher for expect(...).to have_received(:m).with(hash_including(...))
  class HashIncludingMatcher
    def initialize(expected)
      @expected = expected
    end

    def matches?(actual)
      return false unless actual.is_a?(Hash)

      @expected.all? { |k, v| actual[k] == v }
    end

    def ==(other)
      matches?(other)
    end
  end
end

# Integration with Minitest::Spec - expect(obj).to/not_to for mock assertions
module MockExpectIntegration
  # Override expect to handle have_received matchers
  # This wraps minitest's expect to add mock verification support
  def expect(obj_or_val = :__not_provided__, *args, &block)
    if obj_or_val == :__not_provided__ && block
      # Block form: expect { ... } - delegate to super
      super(&block)
    elsif args.empty? && !block
      # Mock verification form: expect(obj)
      MockExpectProxy.new(obj_or_val, self)
    else
      # Standard minitest expect form: expect(value).must_equal(...)
      super(obj_or_val, *args, &block)
    end
  end

  class MockExpectProxy
    def initialize(obj, test_context)
      @obj = obj
      @test_context = test_context
    end

    def to(matcher, &block)
      if matcher.is_a?(MockCompat::HaveReceivedMatcher)
        if block
          call_data = matcher.call_args(@obj)
          if call_data
            block.call(*call_data[:args], **call_data.fetch(:kwargs, {}))
          end
        end
        @test_context.assert(
          matcher.matches?(@obj),
          matcher.failure_message(@obj)
        )
      elsif matcher.respond_to?(:matches?)
        @test_context.assert(matcher.matches?(@obj))
      else
        # Fall back - the matcher might be a simple value for include etc.
        @test_context.assert_includes(@obj, matcher)
      end
    end

    def not_to(matcher)
      if matcher.is_a?(MockCompat::HaveReceivedMatcher)
        @test_context.refute(
          matcher.matches?(@obj),
          matcher.negative_failure_message(@obj)
        )
      elsif matcher.respond_to?(:matches?)
        @test_context.refute(matcher.matches?(@obj))
      end
    end
  end
end
