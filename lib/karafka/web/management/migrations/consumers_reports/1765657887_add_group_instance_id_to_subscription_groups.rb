# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Migrations
        module ConsumersReports
          # Adds the group_instance_id field to subscription groups
          #
          # In schema versions before 1.6.0, subscription groups did not include the
          # group_instance_id field which is used for static group membership tracking.
          #
          # This migration ensures old reports can be processed by adding the field with
          # nil value (indicating no static membership configured).
          class AddGroupInstanceIdToSubscriptionGroups < Base
            self.versions_until = '1.6.0'
            self.type = :consumers_reports

            # @param report [Hash] consumer report to migrate
            def migrate(report)
              consumer_groups = report[:consumer_groups]

              return unless consumer_groups

              consumer_groups.each_value do |cg_details|
                subscription_groups = cg_details[:subscription_groups]

                next unless subscription_groups

                subscription_groups.each_value do |sg_details|
                  next if sg_details.key?(:group_instance_id)

                  sg_details[:group_instance_id] = false
                end
              end
            end
          end
        end
      end
    end
  end
end
