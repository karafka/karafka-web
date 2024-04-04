# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

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
