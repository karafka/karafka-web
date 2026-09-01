# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Health
          # Shared lag roll-up helpers for the per-topic aggregated health models. Both the full
          # health topics view ({AggregatedTopic}) and the cluster lags view
          # ({AggregatedClusterTopic}) expose `measurable_count`, `avg_lag` and `max_lag` (as
          # `HashProxy` values), so the skew detection can live in one place.
          module LagStats
            # @return [Boolean] true when the lag is concentrated on one (or few) partition(s)
            #   rather than spread evenly, that is the biggest single-partition lag is at least
            #   `config.ui.health_lag_skew_threshold`x the average. Only meaningful with more than
            #   one lagging partition. An evenly lagging topic and a topic with one hot/stuck
            #   partition can share the same total lag, so this is what distinguishes them at a
            #   glance.
            def skewed?
              return false if measurable_count < 2
              return false unless avg_lag.positive?

              max_lag >= avg_lag * ::Karafka::Web.config.ui.health_lag_skew_threshold
            end
          end
        end
      end
    end
  end
end
