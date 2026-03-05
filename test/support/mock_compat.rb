# frozen_string_literal: true

# Lightweight mock compatibility layer providing RSpec-like mocking API on top of
# simple method stubbing. This allows tests migrated from RSpec to keep their
# existing mock/stub patterns without a full rewrite.
#
# Supported patterns:
#   allow(obj).to receive(:method).and_return(value)
#   allow(obj).to receive(:method).with(args).and_return(value)
#   allow(obj).to receive(:method).and_call_original
#   allow(obj).to receive(:method).and_raise(error)
#   allow(obj).to receive(:method).and_yield(value)
#   allow(obj).to receive(:method) { |args| block }
#   allow(obj).to receive_messages(method1: val1, method2: val2)
#   expect(obj).to have_received(:method)
#   expect(obj).to have_received(:method).with(args)
#   expect(obj).to have_received(:method).once
#   expect(obj).to have_received(:method).at_least(:once)
#   expect(obj).not_to have_received(:method)
#   expect(obj).to eq(value)
#   expect(obj).to be(value)
#   expect(obj).to include(value)
#   expect(obj).to be_nil
#   expect(obj).to be_truthy
#   expect(obj).to be_within(delta).of(value)
#   expect(obj).to contain_exactly(a, b, c)
#   expect { block }.to raise_error(ErrorClass)
#   expect { block }.to change { value }.from(a).to(b)
#   instance_double(ClassName, method1: val1, ...)
#   stub_const("Const::Name", value)
#   an_instance_of(ClassName)
module MockCompat
  # Registry of all stubs applied during a test, for cleanup
  STUB_REGISTRY = []
  # Registry of stubbed constants, for cleanup
  CONST_REGISTRY = []
  # Registry of method call recordings
  CALL_REGISTRY = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }

  # Check if positional args match for with-constrained stub dispatch
  def self.args_match_dispatch?(expected, actual)
    return true if expected.nil?

    expected.each_with_index.all? do |exp, i|
      if exp.is_a?(AnInstanceOfMatcher)
        exp.matches?(actual[i])
      else
        exp == actual[i]
      end
    end
  end

  # Check if keyword args match for with-constrained stub dispatch
  def self.kwargs_match_dispatch?(expected, actual)
    return true if expected.nil?

    expected.all? { |k, v| actual[k] == v }
  end

  # Clean up all stubs, constants, and call recordings after each test
  #
  # When the same method on the same object is stubbed multiple times (e.g., outer before
  # stubs :sampler, inner context stubs it again), we must:
  # 1. Remove the stub from the singleton class (only once per unique obj+method)
  # 2. Restore the FIRST (true original) saved method, not intermediate stubs
  def self.cleanup!
    # For each unique (obj, method_name), keep only the first (oldest/original) entry
    originals = {}
    STUB_REGISTRY.each do |entry|
      key = [entry[0].__id__, entry[1].to_s]
      originals[key] ||= entry
    end

    # Remove stub and restore original for each unique method
    # Each restoration is wrapped in rescue to prevent one failure from blocking others
    originals.each_value do |obj, method_name, original_for_restore, cleanup_type|
      begin
        obj.singleton_class.remove_method(method_name)
      rescue NameError
        nil
      end

      begin
        # Only restore if it was originally a singleton method
        if cleanup_type == :singleton && original_for_restore.is_a?(Method)
          obj.define_singleton_method(method_name, original_for_restore)
        end
      rescue
        nil
      end
      # For :inherited - inherited method is exposed by removal
      # For :none - method didn't exist, removal is sufficient
    end
    STUB_REGISTRY.clear

    CONST_REGISTRY.each do |parent, const, original|
      parent.send(:remove_const, const) if parent.const_defined?(const, false)
      parent.const_set(const, original) unless original == :__not_defined__
    end
    CONST_REGISTRY.clear

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

  # Alias for instance_double without class verification
  def double(name_or_stubs = nil, stubs = {})
    if name_or_stubs.is_a?(Hash)
      instance_double(Object, name_or_stubs)
    elsif name_or_stubs.is_a?(String) || name_or_stubs.is_a?(Symbol)
      instance_double(Object, stubs)
    else
      instance_double(Object)
    end
  end

  # Temporarily replaces a constant for the duration of a test
  def stub_const(const_name, value)
    parts = const_name.split("::")
    parent = Object

    if parts.length == 1
      const = parts.first.to_sym
    else
      # Build intermediate modules if they don't exist
      parts[0..-2].each do |name|
        unless parent.const_defined?(name, false)
          mod = Module.new
          parent.const_set(name, mod)
          MockCompat::CONST_REGISTRY << [parent, name.to_sym, :__not_defined__]
        end
        parent = parent.const_get(name)
      end
      const = parts.last.to_sym
    end

    original = parent.const_defined?(const, false) ? parent.const_get(const) : :__not_defined__
    parent.send(:remove_const, const) if parent.const_defined?(const, false)
    parent.const_set(const, value)

    MockCompat::CONST_REGISTRY << [parent, const, original]
  end

  # Returns a matcher for have_received assertions
  def have_received(method_name)
    HaveReceivedMatcher.new(method_name)
  end

  # Returns a receive matcher for setting up stubs
  def receive(method_name, &block)
    ReceiveMatcher.new(method_name, &block)
  end

  # Returns a receive_messages matcher for setting up multiple stubs
  def receive_messages(hash)
    ReceiveMessagesMatcher.new(hash)
  end

  # Returns a matcher that checks if a collection contains exactly the given elements (any order)
  def contain_exactly(*expected)
    ContainExactlyMatcher.new(expected)
  end

  # Returns a matcher that checks if a hash includes certain keys
  def hash_including(**expected)
    HashIncludingMatcher.new(expected)
  end

  # Returns an argument matcher for class instance checks
  def an_instance_of(klass)
    AnInstanceOfMatcher.new(klass)
  end

  # Returns an equality matcher
  def eq(expected)
    EqMatcher.new(expected)
  end

  # Returns an identity matcher (object identity via .equal?)
  def be(expected = :__no_arg__)
    if expected == :__no_arg__
      BeIdentityMatcher.new(nil, false)
    else
      BeIdentityMatcher.new(expected, true)
    end
  end

  # Returns an include matcher
  def include(*expected)
    IncludeMatcher.new(expected)
  end

  # Returns a be_nil matcher
  def be_nil
    BeNilMatcher.new
  end

  # Returns a be_truthy matcher
  def be_truthy
    BeTruthyMatcher.new
  end

  # Returns a be_within matcher for numeric proximity checks
  def be_within(delta)
    BeWithinMatcher.new(delta)
  end

  # Dynamic be_* predicate matchers (e.g., be_frozen → frozen?)
  def method_missing(name, *args, &block)
    if name.to_s.start_with?("be_") && args.empty? && !block
      predicate = "#{name.to_s.sub(/^be_/, "")}?"
      DynamicPredicateMatcher.new(predicate)
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    name.to_s.start_with?("be_") || super
  end

  # Returns a raise_error matcher
  def raise_error(*args)
    RaiseErrorMatcher.new(*args)
  end

  # Returns a change matcher
  def change(obj = nil, method_name = nil, &block)
    ChangeMatcher.new(obj, method_name, &block)
  end

  # Returns a yield_with_args matcher for block yield assertions
  def yield_with_args(*expected_args)
    YieldWithArgsMatcher.new(*expected_args)
  end

  # Returns a yield_control matcher for block yield assertions
  def yield_control
    YieldControlMatcher.new
  end

  # Proxy for allow(obj).to receive(...)
  class AllowProxy
    def initialize(obj)
      @obj = obj
    end

    def to(matcher, &block)
      case matcher
      when ReceiveMatcher
        # Support allow(obj).to receive(:method) { |args| block }
        matcher.instance_variable_set(:@return_block, block) if block
        matcher.apply(@obj)
      when ReceiveMessagesMatcher
        matcher.apply(@obj)
      end
    end
  end

  # Matcher for receive(:method).and_return(value) chains
  class ReceiveMatcher
    attr_reader :method_name

    def initialize(method_name, &block)
      @method_name = method_name
      @return_value = nil
      @return_block = block
      @call_original = false
      @raise_error = nil
      @yield_values = nil
      @with_args = nil
      @with_kwargs = nil
    end

    def with(*args, **kwargs)
      @with_args = args
      @with_kwargs = kwargs.empty? ? nil : kwargs
      self
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
      @yield_values ||= []
      @yield_values << values
      self
    end

    def apply(obj)
      method_name = @method_name
      return_value = @return_value
      return_values = @return_values
      return_block = @return_block
      call_original = @call_original
      raise_error = @raise_error
      yield_values = @yield_values
      with_args = @with_args
      with_kwargs = @with_kwargs

      # Determine cleanup strategy
      is_singleton = obj.singleton_methods.include?(method_name.to_sym)
      had_method = obj.respond_to?(method_name)

      # Save original method reference for and_call_original
      original_method = had_method ? obj.method(method_name) : nil

      # Save original singleton method for restoration during cleanup
      original_for_restore = is_singleton ? obj.method(method_name) : nil
      cleanup_type = if is_singleton
        :singleton
      elsif had_method
        :inherited
      else
        :none
      end

      call_count = [0]

      # Build the handler proc for this stub's behavior
      handler = proc do |*args, **kwargs, &block|
        MockCompat::CALL_REGISTRY[obj.__id__][method_name] << {
          args: args, kwargs: kwargs, block: block
        }

        if raise_error
          raise(*raise_error)
        elsif return_block
          return_block.call(*args, **kwargs, &block)
        elsif yield_values && !yield_values.empty?
          result = nil
          yield_values.each { |yv| result = block&.call(*yv) }
          return_value.nil? ? result : return_value
        elsif call_original && original_method
          original_method.call(*args, **kwargs, &block)
        elsif return_values
          idx = [call_count[0], return_values.length - 1].min
          call_count[0] += 1
          return_values[idx]
        else
          return_value
        end
      end

      if with_args || with_kwargs
        # With-constrained stub: chain with previous method so multiple
        # .with() stubs on the same method all work (like RSpec)
        prev_method = had_method ? obj.method(method_name) : nil

        obj.define_singleton_method(method_name) do |*args, **kwargs, &block|
          if MockCompat.args_match_dispatch?(with_args, args) &&
              MockCompat.kwargs_match_dispatch?(with_kwargs, kwargs)
            handler.call(*args, **kwargs, &block)
          elsif prev_method
            prev_method.call(*args, **kwargs, &block)
          end
        end
      else
        # No with constraints - simple stub that handles all calls
        obj.define_singleton_method(method_name) do |*args, **kwargs, &block|
          handler.call(*args, **kwargs, &block)
        end
      end

      MockCompat::STUB_REGISTRY << [obj, method_name, original_for_restore, cleanup_type]
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
      @at_least_count = nil
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

    def at_least(count_or_sym)
      @at_least_count =
        case count_or_sym
        when :once then 1
        when :twice then 2
        else count_or_sym
        end
      self
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
      elsif @at_least_count
        calls.length >= @at_least_count
      else
        calls.length > 0
      end
    end

    def failure_message(obj)
      calls = MockCompat::CALL_REGISTRY[obj.__id__][@method_name]
      "Expected #{obj.class}##{@method_name} to have been called" \
        "#{" #{@count} time(s)" if @count}" \
        "#{" at least #{@at_least_count} time(s)" if @at_least_count}" \
        "#{" with #{@expected_args.inspect}" if @expected_args}" \
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
        elsif exp.is_a?(AnInstanceOfMatcher)
          exp.matches?(actual[i])
        elsif exp.is_a?(Regexp)
          exp.match?(actual[i].to_s)
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

  # Argument matcher for an_instance_of(Class)
  class AnInstanceOfMatcher
    def initialize(klass)
      @klass = klass
    end

    def ==(other)
      other.is_a?(@klass)
    end

    def matches?(actual)
      actual.is_a?(@klass)
    end

    def failure_message(actual)
      "Expected an instance of #{@klass}, but got #{actual.class}"
    end
  end

  # Matcher for expect(collection).to contain_exactly(a, b, c)
  class ContainExactlyMatcher
    def initialize(expected)
      @expected = expected
    end

    def matches?(actual)
      return false unless actual.respond_to?(:sort)

      actual.sort == @expected.sort
    rescue ArgumentError
      actual.to_a.length == @expected.length && @expected.all? { |e| actual.include?(e) }
    end

    def failure_message(actual)
      "Expected collection to contain exactly #{@expected.inspect}, but got #{actual.inspect}"
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

  # Dynamic predicate matcher for be_* patterns (e.g., be_frozen → frozen?)
  class DynamicPredicateMatcher
    def initialize(predicate)
      @predicate = predicate
    end

    def matches?(actual)
      actual.public_send(@predicate)
    end

    def failure_message(actual)
      "Expected #{actual.inspect} to be #{@predicate.chomp("?")}"
    end
  end

  # Matcher for expect(value).to eq(expected)
  class EqMatcher
    def initialize(expected)
      @expected = expected
    end

    def matches?(actual)
      actual == @expected
    end

    def failure_message(actual)
      "Expected #{actual.inspect} to equal #{@expected.inspect}"
    end
  end

  # Matcher for expect(value).to be(expected) - object identity
  class BeIdentityMatcher
    def initialize(expected, has_arg)
      @expected = expected
      @has_arg = has_arg
    end

    def matches?(actual)
      actual.equal?(@expected)
    end

    def failure_message(actual)
      "Expected #{actual.inspect} (#{actual.class}) to be the same object as " \
        "#{@expected.inspect} (#{@expected.class})"
    end
  end

  # Matcher for expect(value).to include(expected)
  class IncludeMatcher
    def initialize(expected)
      @expected = expected
    end

    def matches?(actual)
      @expected.all? do |exp|
        if actual.is_a?(Hash) && exp.is_a?(Hash)
          exp.all? { |k, v| actual[k] == v }
        else
          actual.include?(exp)
        end
      end
    end

    def failure_message(actual)
      "Expected #{actual.inspect} to include #{@expected.inspect}"
    end
  end

  # Matcher for expect(value).to be_nil
  class BeNilMatcher
    def matches?(actual)
      actual.nil?
    end

    def failure_message(actual)
      "Expected nil, but got #{actual.inspect}"
    end
  end

  # Matcher for expect(value).to be_truthy
  class BeTruthyMatcher
    def matches?(actual)
      !!actual
    end

    def failure_message(actual)
      "Expected truthy value, but got #{actual.inspect}"
    end
  end

  # Matcher for expect(value).to be_within(delta).of(expected)
  class BeWithinMatcher
    def initialize(delta)
      @delta = delta
      @expected = nil
    end

    def of(expected)
      @expected = expected
      self
    end

    def matches?(actual)
      return false unless @expected

      (actual - @expected).abs <= @delta
    end

    def failure_message(actual)
      "Expected #{actual.inspect} to be within #{@delta} of #{@expected.inspect}"
    end
  end

  # Matcher for expect { |b| method(&b) }.to yield_with_args(expected)
  # The block receives a probe proc; the method under test calls it with args
  class YieldWithArgsMatcher
    def initialize(*expected_args)
      @expected_args = expected_args
      @yielded = false
      @actual_args = nil
    end

    def block_matches?(block)
      probe = proc do |*args|
        @yielded = true
        @actual_args = args
      end
      block.call(probe)
      @yielded && args_match?
    end

    def failure_message(_actual = nil)
      if @yielded
        "Expected block to yield with #{@expected_args.inspect}, " \
          "but yielded with #{@actual_args.inspect}"
      else
        "Expected block to yield with args, but did not yield"
      end
    end

    private

    def args_match?
      return true if @expected_args.empty?

      @expected_args.each_with_index.all? do |exp, i|
        exp == @actual_args[i]
      end
    end
  end

  # Matcher for expect { |b| method(&b) }.to/not_to yield_control
  class YieldControlMatcher
    def initialize
      @yielded = false
    end

    def block_matches?(block)
      probe = proc { |*_args| @yielded = true }
      block.call(probe)
      @yielded
    end

    def failure_message(_actual = nil)
      "Expected block to yield control, but did not"
    end

    def negative_failure_message(_actual = nil)
      "Expected block not to yield control, but it did"
    end
  end

  # Matcher for expect { block }.to raise_error(ErrorClass, message)
  class RaiseErrorMatcher
    def initialize(error_class = StandardError, message = nil)
      @error_class = error_class
      @message = message
    end

    def block_matches?(block)
      block.call
      @matched = false
      false
    rescue @error_class => e
      @matched = if @message
        e.message.include?(@message.to_s) || e.message == @message.to_s
      else
        true
      end
      @raised_error = e
      @matched
    rescue => e
      @raised_error = e
      @matched = false
      false
    end

    def failure_message(_actual = nil)
      if @raised_error
        "Expected #{@error_class}#{" with message '#{@message}'" if @message}, " \
          "but got #{@raised_error.class}: #{@raised_error.message}"
      else
        "Expected #{@error_class}#{" with message '#{@message}'" if @message} to be raised, but nothing was raised"
      end
    end
  end

  # Matcher for expect { block }.to change { value }.from(a).to(b)
  # Also supports expect { block }.to change(obj, :method).from(a).to(b)
  class ChangeMatcher
    def initialize(obj = nil, method_name = nil, &block)
      if block
        @value_block = block
      elsif obj && method_name
        @value_block = -> { obj.public_send(method_name) }
      end
      @from = :__not_set__
      @to = :__not_set__
    end

    def from(expected)
      @from = expected
      self
    end

    def to(expected)
      @to = expected
      self
    end

    def block_matches?(block)
      @before_value = @value_block.call
      block.call
      @after_value = @value_block.call

      changed = @before_value != @after_value
      from_ok = @from == :__not_set__ || @before_value == @from
      to_ok = @to == :__not_set__ || @after_value == @to

      changed && from_ok && to_ok
    end

    def failure_message(_actual = nil)
      if @from != :__not_set__ && @to != :__not_set__
        "Expected value to change from #{@from.inspect} to #{@to.inspect}, " \
          "but was #{@before_value.inspect} before and #{@after_value.inspect} after"
      else
        "Expected value to change, but was #{@before_value.inspect} before and #{@after_value.inspect} after"
      end
    end

    def negative_failure_message(_actual = nil)
      "Expected value not to change, but changed from #{@before_value.inspect} to #{@after_value.inspect}"
    end
  end
end

# Integration with Minitest::Spec - expect(obj).to/not_to for mock assertions
module MockExpectIntegration
  # Override expect to handle have_received matchers and RSpec-style expectations
  # This wraps minitest's expect to add mock verification support
  def expect(obj_or_val = :__not_provided__, *args, &block)
    if obj_or_val == :__not_provided__ && block
      # Block form: expect { ... } - return proxy for raise_error, change etc.
      BlockExpectProxy.new(block, self)
    elsif args.empty? && !block
      # Mock verification form: expect(obj)
      MockExpectProxy.new(obj_or_val, self)
    else
      # Standard minitest expect form: expect(value).must_equal(...)
      super
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
        msg = matcher.respond_to?(:failure_message) ? matcher.failure_message(@obj) : nil
        @test_context.assert(matcher.matches?(@obj), msg)
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

  class BlockExpectProxy
    def initialize(block, test_context)
      @block = block
      @test_context = test_context
    end

    def to(matcher)
      if matcher.respond_to?(:block_matches?)
        msg = matcher.respond_to?(:failure_message) ? matcher.failure_message(nil) : nil
        @test_context.assert(matcher.block_matches?(@block), msg)
      else
        @test_context.flunk("Unsupported block matcher: #{matcher.class}")
      end
    end

    def not_to(matcher)
      if matcher.respond_to?(:block_matches?)
        result = matcher.block_matches?(@block)
        msg = matcher.respond_to?(:negative_failure_message) ? matcher.negative_failure_message(nil) : nil
        @test_context.refute(result, msg)
      else
        @test_context.flunk("Unsupported block matcher: #{matcher.class}")
      end
    end
  end
end
