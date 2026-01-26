# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Routes
        # Manages the jobs related routes
        class Jobs < Base
          route do |r|
            r.on "jobs" do
              controller = build(Controllers::JobsController)

              r.get "running" do
                controller.running
              end

              r.get "pending" do
                controller.pending
              end

              r.redirect root_path("jobs/running")
            end
          end
        end
      end
    end
  end
end
