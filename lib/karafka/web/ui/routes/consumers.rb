# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Routes
        # Manages the consumers related routes
        class Consumers < Base
          route do |r|
            r.on 'consumers' do
              %w[
                performance
                controls
                commands
              ].each do |path|
                r.get path do |_process_id|
                  raise Errors::Ui::ProOnlyError
                end
              end

              r.get String, 'subscriptions' do |_process_id|
                raise Errors::Ui::ProOnlyError
              end

              r.get do
                controller = Controllers::ConsumersController.new(params)
                controller.index
              end
            end
          end
        end
      end
    end
  end
end
