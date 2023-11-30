# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      # Non info related extra components used in the UI
      module Lib
        # Proxy for hashes we use across UI.
        # Often we have nested values we want to extract or just values we want to reference and
        # this object drastically simplifies that.
        #
        # It is mostly used for flat hashes.
        #
        # It is in a way similar to openstruct but has abilities to dive deep into objects
        #
        # It is not super fast but it is enough for the UI and how deep structures we have.
        class HashProxy
          extend Forwardable

          def_delegators :@hash, :[], :[]=, :key?, :each, :find, :values, :keys, :select

          # @param hash [Hash] hash we want to convert to a proxy
          def initialize(hash)
            @hash = hash
            # Nodes we already visited in the context of a given attribute lookup
            # We cache them not to look for them over and over again if they are used more than
            # once
            @visited = Hash.new { |h, k| h[k] = {} }
            # Methods invocations cache
            @results = {}
          end

          # @return [Original hash]
          def to_h
            @hash
          end

          # @param method_name [String] method name
          # @param args [Object] all the args of the method
          # @param block [Proc] block for the method
          def method_missing(method_name, *args, &block)
            method_name = method_name.to_sym

            return super unless args.empty? && block.nil?
            return @results[method_name] if @results.key?(method_name)

            result = deep_find(@hash, method_name)

            return super if result.nil?

            @results[method_name] = result
          end

          # @param method_name [String] method name
          # @param include_private [Boolean]
          def respond_to_missing?(method_name, include_private = false)
            method_name = method_name.to_sym

            return true if @results.key?(method_name)

            result = deep_find(@hash, method_name)

            return super if result.nil?

            @results[method_name] = result

            true
          end

          private

          # @param obj [Object] local scope of iterating
          # @param key [Symbol, String] key we are looking for
          def deep_find(obj, key)
            # Prevent circular dependency lookups by making sure we do not check the same object
            # multiple times
            return nil if @visited[key].key?(obj)

            @visited[key][obj] = nil

            if obj.respond_to?(:key?) && obj.key?(key)
              obj[key]
            elsif obj.respond_to?(:each)
              result = nil
              obj.find { |*a| result = deep_find(a.last, key) }
              result
            end
          end
        end
      end
    end
  end
end
