# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Routes
        # Manages the pro only related routes that OSS users can go to to get Pro info
        class ProOnly < Base
          route do |r|
            %w[
              health
              explorer
              dlq
              topics
              recurring_tasks
              scheduled_messages
            ].each do |route|
              r.get route, [String, true], [String, true] do
                raise ::Karafka::Web::Errors::Ui::ProOnlyError
              end
            end
          end
        end
      end
    end
  end
end
