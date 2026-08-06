# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Helpers
        # Helpers mapping domain states (process status, kafka state, lag trend) to badge styles
        # and rendering simple badge collections
        module BadgesHelper
          # Takes a status and recommends background style color
          #
          # @param status [String] status
          # @return [String] background style
          def status_badge(status)
            case status
            when "initialized" then "badge-success"
            when "supervising" then "badge-success"
            when "running" then "badge-success"
            when "quieting" then "badge-warning"
            when "quiet" then "badge-warning"
            when "stopping" then "badge-warning"
            when "stopped" then "badge-error"
            when "terminated" then "badge-error"
            else
              raise ::Karafka::Errors::UnsupportedCaseError, status
            end
          end

          # Takes the lag trend and gives it appropriate background style color for badge
          #
          # @param trend [Numeric] lag trend
          # @return [String] bg classes
          def lag_trend_badge(trend)
            bg = "badge-success" if trend.negative?
            bg ||= "badge-warning" if trend.positive?
            bg ||= "badge-secondary"
            bg
          end

          # Renders tags one after another
          #
          # @param tags_array [Array<String>]
          # @return [String] tags badges
          def tags(tags_array)
            tags_array
              .map { |tag| %(<span class="badge badge-info">#{tag}</span>) }
              .join(" ")
          end

          # Takes a kafka report state and recommends background style color
          # @param state [String] state
          # @return [String] background style
          def kafka_state_badge(state)
            case state
            when "up" then "badge-success"
            when "active" then "badge-success"
            when "steady" then "badge-success"
            else
              "badge-warning"
            end
          end
        end
      end
    end
  end
end
