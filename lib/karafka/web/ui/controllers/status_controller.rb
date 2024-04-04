# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # View that helps understand the status of the Web UI
        # Many people reported problems understanding the requirements or misconfigured things.
        # While all of the things are documented, people are lazy. Hence we provide a status
        # page where we check that everything is as expected and if not, we can provide some
        # helpful instructions on how to fix the issues.
        class StatusController < BaseController
          # Displays the Web UI setup status
          def show
            @status = Models::Status.new
            @sampler = Tracking::Sampler.new

            render
          end
        end
      end
    end
  end
end
