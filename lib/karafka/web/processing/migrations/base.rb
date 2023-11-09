# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      # Namespace for storing migrations of our Web UI topics data
      module Migrations
        class Base
          class << self
            attr_accessor :created_at
            # First version that should not be affected by this process
            attr_accessor :versions_until
            attr_accessor :type
          end

          def migrate(state)
            state
          end
        end
      end
    end
  end
end
