# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if the commands topic exists for Pro users.
            #
            # The commands topic (karafka_consumers_commands) is used by Pro features
            # like consumer commanding (pause, resume, trace, etc.). While it's created
            # by CreateTopics for all users (to allow smooth upgrades), it's only
            # actively used by Pro users.
            #
            # For OSS users, this check always succeeds since they don't use commanding.
            # For Pro users, it warns if the topic is missing.
            class CommandsTopicPresence < Base
              depends_on :topics

              # Executes the commands topic presence check.
              #
              # @return [Status::Step] success if not Pro or if topic exists,
              #   warning if Pro and topic is missing
              def call
                # OSS users don't need the commands topic
                return step(:success) unless ::Karafka.pro?

                topic_name = context.topics_consumers_commands
                present = topic_present?(topic_name)

                step(present ? :success : :warning, { topic_name: topic_name, present: present })
              end

              private

              # Checks if a topic exists in the cluster.
              #
              # @param topic_name [String] the topic name to check
              # @return [Boolean] true if the topic exists
              def topic_present?(topic_name)
                context.cluster_info.topics.any? do |topic|
                  topic[:topic_name] == topic_name
                end
              end
            end
          end
        end
      end
    end
  end
end
