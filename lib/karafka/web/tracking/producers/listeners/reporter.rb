# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Producers
        module Listeners
          # Special listener that we use to report data about producers states
          # We don't have to have a separate thread for reporting, because producers have their
          # own internal threads for changes polling and we can utilize this thread
          class Reporter < Base
            # @param _event [Karafka::Core::Monitoring::Event]
            def on_statistics_emitted(_event)
              reporter.report
            end
          end
        end
      end
    end
  end
end
