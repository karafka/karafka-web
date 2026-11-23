# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersReports
          # Adds the member_id field to subscription groups
          #
          # In schema versions before 1.8.0, subscription groups did not include the member_id
          # field which holds the group member id the cluster assigned to the consumer.
          #
          # This migration ensures old reports can be processed by adding the field with an empty
          # string, which is how Kafka represents a member id that is not known.
          class AddMemberIdToSubscriptionGroups < Base
            self.versions_until = "1.8.0"
            self.type = :consumers_reports

            # @param report [Hash] consumer report to migrate
            def migrate(report)
              consumer_groups = report[:consumer_groups]

              return unless consumer_groups

              consumer_groups.each_value do |cg_details|
                subscription_groups = cg_details[:subscription_groups]

                next unless subscription_groups

                subscription_groups.each_value do |sg_details|
                  next if sg_details.key?(:member_id)

                  sg_details[:member_id] = ""
                end
              end
            end
          end
        end
      end
    end
  end
end
