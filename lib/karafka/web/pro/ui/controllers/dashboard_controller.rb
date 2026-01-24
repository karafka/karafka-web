# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

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
