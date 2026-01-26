# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Helpers
        # Helper with time-related methods
        module TimeHelper
          # @param time [Float] UTC time float
          # @return [String] relative time tag for timeago.js
          def relative_time(time)
            stamp = Time.at(time).getutc.iso8601(3)
            %(<time class="ltr" dir="ltr" title="#{stamp}" datetime="#{stamp}">#{time}</time>)
          end

          # @param time [Time] time object we want to present with detailed ms label
          # @return [String] span tag with raw timestamp as a title and time as a value
          def time_with_label(time)
            stamp = (time.to_f * 1000).to_i

            %(<span title="#{stamp}">#{time}</span>)
          end

          # Converts raw second count into human readable form like "12.2 minutes". etc based on
          # number of seconds
          #
          # @param seconds [Numeric] number of seconds
          # @return [String] human readable time
          def human_readable_time(seconds)
            case seconds
            when 0..59
              "#{seconds.round(2)} seconds"
            when 60..3_599
              minutes = seconds / 60.0
              "#{minutes.round(2)} minutes"
            when 3_600..86_399
              hours = seconds / 3_600.0
              "#{hours.round(2)} hours"
            else
              days = seconds / 86_400.0
              "#{days.round(2)} days"
            end
          end

          # @param state [String] poll state
          # @param state_ch [Integer] time until next change of the poll state
          #   (from paused to active)
          # @return [String] span tag with label and title with change time if present
          def poll_state_with_change_time_label(state, state_ch)
            year_in_seconds = 131_556_926
            state_ch_in_seconds = state_ch / 1_000.0

            # If state is active, there is no date of change
            if state == "active"
              %(
                <span class="badge #{kafka_state_badge(state)}">#{state}</span>
              )
            elsif state_ch_in_seconds > year_in_seconds
              %(
                <span
                  class="badge #{kafka_state_badge(state)}"
                  title="until manual resume"
                >
                  #{state}
                </span>
              )
            else
              %(
                <span
                  class="badge #{kafka_state_badge(state)} time-title"
                  title="#{Time.now + state_ch_in_seconds}"
                >
                  #{state}
                </span>
              )
            end
          end
        end
      end
    end
  end
end
