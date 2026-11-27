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
        end
      end
    end
  end
end
