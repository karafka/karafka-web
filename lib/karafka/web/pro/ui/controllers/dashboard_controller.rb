# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          # Main Karafka Pro Web-Ui dashboard controller
          class DashboardController < BaseController
            include Web::Ui

            # View with statistics dashboard details
            def index
              @current_state = Models::ConsumersState.current!
              @counters = Models::Counters.new(@current_state)

              current_metrics = Models::ConsumersMetrics.current!

              # Build the charts data using the aggregated metrics
              @aggregated = Models::Metrics::Aggregated.new(
                current_metrics.to_h.fetch(:aggregated)
              )

              # Build the charts data about topics using the consumers groups metrics
              @topics = Models::Metrics::Topics.new(
                current_metrics.to_h.fetch(:consumer_groups)
              )

              # Load only historicals for the selected range
              @aggregated_charts = Models::Metrics::Charts::Aggregated.new(
                @aggregated, @params.current_range
              )

              @topics_charts = Models::Metrics::Charts::Topics.new(
                @topics, @params.current_range
              )

              render
            end
          end
        end
      end
    end
  end
end
