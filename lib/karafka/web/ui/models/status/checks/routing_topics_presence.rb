# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if all active topics in the routing exist in the cluster.
            #
            # This identifies topics that are configured in the routing but don't
            # actually exist in Kafka. Pattern-based topics are excluded from this
            # check since they may not exist yet.
            #
            # @note This is a warning-only check - missing topics don't block
            #   the dependency chain but should be addressed.
            class RoutingTopicsPresence < Base
              depends_on :consumers_reports_schema_state

              class << self
                # @return [Array] empty array for halted state
                def halted_details
                  []
                end
              end

              # Executes the routing topics presence check.
              #
              # Compares routed topics against existing cluster topics.
              #
              # @return [Status::Step] success if all exist, warning if any missing
              def call
                existing = context.cluster_info.topics.map { |topic| topic[:topic_name] }

                missing = ::Karafka::App
                          .routes
                          .flat_map(&:topics)
                          .flat_map { |topics| topics.map(&:itself) }
                          .select(&:active?)
                          .reject { |topic| topic.respond_to?(:patterns?) ? topic.patterns? : nil }
                          .map(&:name)
                          .uniq
                          .then { |routed_topics| routed_topics - existing }

                step(missing.empty? ? :success : :warning, missing)
              end
            end
          end
        end
      end
    end
  end
end
