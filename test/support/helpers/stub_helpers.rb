# frozen_string_literal: true

# Helpers for common Mocha stubbing patterns
module StubHelpers
  # Registry of passthrough stubs for cleanup
  PASSTHROUGH_REGISTRY = []

  # Stubs a method while preserving the original implementation.
  # Useful when you need to spy on calls to a method without changing its behavior,
  # or as a passthrough default before adding .with()-constrained stubs.
  def stub_and_passthrough(obj, method_name)
    original = obj.method(method_name)
    is_singleton = obj.singleton_methods.include?(method_name.to_sym)
    original_for_restore = is_singleton ? obj.method(method_name) : nil

    obj.define_singleton_method(method_name) do |*args, **kwargs, &blk|
      original.call(*args, **kwargs, &blk)
    end

    PASSTHROUGH_REGISTRY << [obj, method_name, original_for_restore, is_singleton]
  end

  # Clean up passthrough stubs
  def self.cleanup!
    PASSTHROUGH_REGISTRY.each do |obj, method_name, original_for_restore, is_singleton|
      begin
        obj.singleton_class.remove_method(method_name)
      rescue NameError
        nil
      end

      begin
        if is_singleton && original_for_restore
          obj.define_singleton_method(method_name, original_for_restore)
        end
      rescue StandardError
        nil
      end
    end
    PASSTHROUGH_REGISTRY.clear
  end
end
