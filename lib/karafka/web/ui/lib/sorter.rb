# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        # Sorting engine for deep in-memory structures
        # It supports hashes, arrays and hash proxies.
        #
        # @note It handles sorting in place by mutating appropriate resources and sub-components
        class Sorter
          # We can support only two order types
          ALLOWED_ORDERS = %w[asc desc].freeze

          # Max depth for nested sorting
          MAX_DEPTH = 10

          private_constant :ALLOWED_ORDERS, :MAX_DEPTH

          # @param sort_query [String] query for sorting or empty string if no sorting needed
          def initialize(sort_query)
            field, order = sort_query.split(' ')

            @order = order.to_s.downcase
            @order = ALLOWED_ORDERS.first unless ALLOWED_ORDERS.include?(@order)

            # Normalize the key since we do not operate on capitalized values
            @field = field.to_s.downcase

            # Things we have already seen and sorted. Prevents crashing on the circular
            # dependencies sorting when same resources are present in different parts of the three
            @seen = []
          end

          # Sorts the structure and returns it sorted.
          #
          # @param resource [Hash, Array, Lib::HashProxy] structure we want to sort
          # @param current_depth []
          def call(resource, current_depth = 0)
            # Skip if there is no sort field at all
            return resource if @field.empty?
            # Skip if we've already seen this resource
            return resource if @seen.include?(resource)
            # Skip if we are too deep
            return resource if current_depth > MAX_DEPTH

            @seen << resource

            case resource
            when Array
              sort_array!(resource, current_depth)
            when Hash
              sort_hash!(resource, current_depth)
            when Lib::HashProxy
              # We can short hash in place here, because it will be still references (the same)
              # in the hash proxy object, so we can do it that way
              sort_hash!(resource.to_h, current_depth)
            end

            resource
          end

          private

          # Sorts the hash in place
          #
          # @param hash [Hash] hash we want to sort
          # @param current_depth [Integer] current depth of sorting from root
          def sort_hash!(hash, current_depth)
            # Run sorting on each value, since we may have nested hashes and arrays
            hash.each_value { |value| call(value, current_depth + 1) }

            hash.each_value do |value|
              return unless value.is_a?(Hash) || value.is_a?(Lib::HashProxy)
              return if sortable_value(value).nil?
            end

            # Generate new hash that will have things in our desired order
            sorted = hash
                     .sort_by { |_, value| sortable_value(value) }
                     .then { |ordered| desc? ? ordered.reverse : ordered }
                     .to_h

            # Clear our hash and inject the new values in the order in which we want to have them
            # Such clear and merge will ensure things are in the order we desired them
            hash.clear
            hash.merge!(sorted)
          end

          # Sorts an array in-place based on a specified attribute.
          #
          # The method iterates over each element in the array and applies the transformation.
          #
          # @param array [Array<Object>] The array of elements to be sorted
          # @param current_depth [Integer] The current depth of the sorting operation,
          #   used in the `call` method to handle nested structures or recursion.
          # @note This method modifies the array in place (mutates the caller).
          def sort_array!(array, current_depth)
            # Sort arrays containing hashes by a specific attribute
            array
              .map! { |element| call(element, current_depth + 1) }
              .sort_by! { |element| sortable_value(element) }
              .tap { |array| desc? ? array.reverse! : array }
          end

          # @return [Boolean] true if we sort in desc, otherwise false
          def desc?
            @order == 'desc'
          end

          # Extracts the attribute based on which we should sort (if present)
          #
          # @param element [Object] takes the element object and depending on its type, tries to
          #   figure out the value based on which we may sort
          # @return [Object, nil] sortable value or nil if nothing to sort
          def sortable_value(element)
            if element.is_a?(Hash)
              return element[@field] || element[@field.to_sym]
            end

            if element.is_a?(Lib::HashProxy)
              return element.respond_to?(@field) ? element.public_send(@field) : nil
            end

            element
          end
        end
      end
    end
  end
end
