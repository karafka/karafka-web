# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Main Karafka Pro Web-Ui dashboard controller
        class DashboardController < Ui::Controllers::BaseController
          # View with statistics dashboard details
          def index
            @current_state = Models::ConsumersState.current!
            @counters = Models::Counters.new(@current_state)

            current_metrics = Models::ConsumersMetrics.current!

            # Build the charts data using the aggregated metrics
            @aggregated = Models::Metrics::Aggregated.new(
              current_metrics.to_h.fetch(:aggregated)
            )

            # Load only historicals for the selected range
            @aggregated_charts = Models::Metrics::Charts::Aggregated.new(
              @aggregated, @params.current_range
            )

            @topics = Models::Metrics::Topics.new(
              current_metrics.to_h.fetch(:consumer_groups)
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
