# frozen_string_literal: true

module Karafka
  module Web
    module Management
      # Namespace for storing migrations of our Web UI topics data
      module Migrations
        # Base for all our migrations
        #
        # Each migration **MUST** have a `#migrate` method defined
        # Migrations are expected to modify the provided state **IN PLACE**
        class Base
          include Karafka::Core::Helpers::Time

          class << self
            # First version that should **NOT** be affected by this migration
            attr_accessor :versions_until
            # What resource does it relate it
            # One migration should modify only one resource type
            attr_accessor :type

            # @param version [String] sem-ver version
            # @return [Boolean] is the given migration applicable
            def applicable?(version)
              version < versions_until
            end

            # @param state [Hash] deserialized state to be modified
            def migrate(state)
              raise NotImplementedError, 'Implement in a subclass'
            end

            # @return [Integer] index for sorting. Older migrations are always applied first
            def index
              instance_method(:migrate)
                .source_location
                .first
                .split('/')
                .last
                .split('_')
                .first
                .to_i
            end

            # @return [Array<Class>] array with migrations sorted from oldest to latest. This is
            #   the order in which they need to be applied
            def sorted_descendants
              ObjectSpace
                .each_object(Class)
                .select { |klass| klass != self && klass.ancestors.include?(self) }
                .sort_by(&:index)
            end
          end
        end
      end
    end
  end
end
