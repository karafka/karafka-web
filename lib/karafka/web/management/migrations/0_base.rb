# frozen_string_literal: true

module Karafka
  module Web
    module Management
      # Namespace for storing migrations of our Web UI topics data
      module Migrations
        class Base
          include Karafka::Core::Helpers::Time

          class << self
            # First version that should not be affected by this process
            attr_accessor :versions_until
            attr_accessor :type

            def applicable?(version)
              version < versions_until
            end

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

            def sorted_descendants
              ObjectSpace
                .each_object(Class)
                .select { |klass| klass < self }
                .sort_by(&:index)
            end
          end
        end
      end
    end
  end
end
