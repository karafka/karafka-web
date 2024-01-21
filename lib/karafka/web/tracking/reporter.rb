# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      # Base reporter from which all the reports should inherit
      class Reporter
        include ::Karafka::Core::Helpers::Time

        # Can this reporter report. Since some reporters may report only in part of the processes
        # where Karafka is used (like `karafka server`) each may implement more complex rules.
        #
        # The basic is not to report unless we have a producer and this producer is active
        #
        # @return [Boolean]
        def active?
          return false unless ::Karafka::Web.producer
          return false unless ::Karafka::Web.producer.status.active?
          return false unless ::Karafka::Web.config.tracking.active

          true
        end
      end
    end
  end
end
