# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Migrations
        class AddInitialMetrics < Base
          self.created_at = 0
          self.versions_until = '0.0.1'
          self.type = :consumers_metrics

          def migrate(state)
            raise
          end
        end
      end
    end
  end
end
