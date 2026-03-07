# frozen_string_literal: true

# Helper for temporarily replacing constants during tests
module StubConstHelper
  # Registry of stubbed constants, for cleanup
  CONST_REGISTRY = []

  # Temporarily replaces a constant for the duration of a test
  def stub_const(const_name, value)
    parts = const_name.split("::")
    parent = Object

    if parts.length == 1
      const = parts.first.to_sym
    else
      parts[0..-2].each do |name|
        unless parent.const_defined?(name, false)
          mod = Module.new
          parent.const_set(name, mod)
          StubConstHelper::CONST_REGISTRY << [parent, name.to_sym, :__not_defined__]
        end
        parent = parent.const_get(name)
      end
      const = parts.last.to_sym
    end

    original = parent.const_defined?(const, false) ? parent.const_get(const) : :__not_defined__
    parent.send(:remove_const, const) if parent.const_defined?(const, false)
    parent.const_set(const, value)

    StubConstHelper::CONST_REGISTRY << [parent, const, original]
  end

  # Clean up stubbed constants
  def self.cleanup!
    CONST_REGISTRY.each do |parent, const, original|
      parent.send(:remove_const, const) if parent.const_defined?(const, false)
      parent.const_set(const, original) unless original == :__not_defined__
    end
    CONST_REGISTRY.clear
  end
end
