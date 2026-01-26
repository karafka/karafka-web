# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if there is a subscription to the reports topic being actively consumed.
            #
            # The Web UI requires an active consumer processing the reports topic
            # to calculate and update the state. This check verifies that subscription
            # exists.
            class StateCalculation < Base
              depends_on :materializing_lag

              # Executes the state calculation check.
              #
              # Looks for the reports topic in the list of subscribed topics
              # from the health data. Caches subscriptions in context.
              #
              # @return [Status::Step] success if subscribed, failure otherwise
              def call
                context.subscriptions ||= Models::Health
                  .current(context.current_state)
                  .values.map { |consumer_group| consumer_group[:topics] }
                  .flat_map(&:keys)

                subscribed = context.subscriptions.include?(context.topics_consumers_reports)

                step(subscribed ? :success : :failure)
              end
            end
          end
        end
      end
    end
  end
end
