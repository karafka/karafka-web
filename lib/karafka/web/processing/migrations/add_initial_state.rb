# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Migrations
        class AddInitialState < Base
          self.created_at = 0
          self.versions_until = '0.0.1'
          self.type = :consumers_state

          def migrate(state)
            {
              processes: {},
              stats: {
                batches: 0,
                messages: 0,
                retries: 0,
                dead: 0,
                busy: 0,
                enqueued: 0,
                processing: 0,
                workers: 0,
                processes: 0,
                rss: 0,
                listeners: 0,
                utilization: 0,
                errors: 0,
                lag_stored: 0,
                lag: 0
             },
             :schema_state=>"accepted",
             :schema_version=>"1.1.0",
             :dispatched_at=>1699547097.6254404}

          end
        end
      end
    end
  end
end
