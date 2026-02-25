# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersReports
          # Adds the poll_interval field to subscription group state
          #
          # In schema versions before 1.7.0, subscription groups did not include the
          # poll_interval field which tracks the max.poll.interval.ms configuration.
          #
          # This migration ensures old reports can be processed by adding the field with
          # the Kafka default value of 300000ms (5 minutes).
          class AddPollIntervalToSubscriptionGroups < Base
            # Reference the canonical default from Sampler to avoid duplication
            DEFAULT_POLL_INTERVAL_MS = ::Karafka::Web::Tracking::Consumers::Sampler::DEFAULT_POLL_INTERVAL_MS

            self.versions_until = "1.7.0"
            self.type = :consumers_reports

            # @param report [Hash] consumer report to migrate
            def migrate(report)
              consumer_groups = report[:consumer_groups]

              return unless consumer_groups

              consumer_groups.each_value do |cg_details|
                subscription_groups = cg_details[:subscription_groups]

                next unless subscription_groups

                subscription_groups.each_value do |sg_details|
                  state = sg_details[:state]

                  next unless state
                  next if state.key?(:poll_interval)

                  state[:poll_interval] = DEFAULT_POLL_INTERVAL_MS
                end
              end
            end
          end
        end
      end
    end
  end
end
