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
        class HashProxy
          # @param hash [Hash] hash we want to convert to a proxy
          def initialize(hash)
            @hash = hash
          end

          # @param key [Object] hash key
          # @return [Object] key content or nil if missing
          def [](key)
            @hash[key]
          end

          # @return [Original hash]
          def to_h
            @hash
          end

          # @param method_name [String] method name
          # @param args [Object] all the args of the method
          # @param block [Proc] block for the method
          def method_missing(method_name, *args, &block)
            return super unless args.empty? && block.nil?

            result = deep_find(@hash, method_name.to_sym)
            result.nil? ? super : result
          end

          # @param method_name [String] method name
          # @param include_private [Boolean]
          def respond_to_missing?(method_name, include_private = false)
            result = deep_find(@hash, method_name.to_sym)
            result.nil? ? super : true
          end

          private

          # @param obj [Object] local scope of iterating
          # @param key [Symbol, String] key we are looking for
          def deep_find(obj, key)
            if obj.respond_to?(:key?) && obj.key?(key)
              obj[key]
            elsif obj.respond_to?(:each)
              r = nil
              obj.find { |*a| r = deep_find(a.last, key) }
              r
            end
          end
        end
      end
    end
  end
end
