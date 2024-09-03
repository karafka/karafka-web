# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Namespace for models representing recurring tasks related components taken from Kafka
        module RecurringTasks
          # Karafka schedule representation
          class Schedule < Web::Ui::Lib::HashProxy
            # Rdkafka errors we expect and handle gracefully
            EXPECTED_RDKAFKA_ERRORS = %i[
              unknown_topic
              unknown_partition
              unknown_topic_or_part
            ].freeze

            private_constant :EXPECTED_RDKAFKA_ERRORS

            class << self
              # @return [Schedule, false] current schedule or false if it was not possible to
              #   get it because requested topic/partition does not exist or nothing was present
              def current
                messages = Karafka::Admin.read_topic(
                  config.topics.schedules,
                  0,
                  # We work here with the assumption that users won't click so fast to load
                  # more than 20 commands prior to a state flush. If that happens, this will
                  # return false. This is a known and expected limitation.
                  20
                )

                # Out of those messages we pick the most recent persisted schedule
                candidate = messages
                            .reverse
                            .find { |message| message.key == 'state:schedule' }

                # If there is a schedule message we use its data to build schedule, if not false
                return false unless candidate

                # If the deserializer is not our dedicated recurring tasks deserializer, it means
                # that routing for recurring tasks was not loaded, so recurring tasks are not
                # active
                #
                # User might have used recurring tasks previously and disabled them, but still may
                # navigate to them and then we should not show anything because without the
                # correct deserializer it will crash anyhow
                return false unless candidate.metadata.deserializers.payload == config.deserializer

                new(candidate.payload)
              rescue Rdkafka::RdkafkaError => e
                # If any of "topic missing" is raised, we return false but other errors we re-raise
                raise(e) unless EXPECTED_RDKAFKA_ERRORS.any? { |code| e.code == code }

                false
              end

              private

              # @return [Karafka::Core::Configurable::Node]
              def config
                Karafka::App.config.recurring_tasks
              end
            end

            # @return [Array<Task>] tasks of the current schedule
            def tasks
              @tasks ||= super.values.map { |task_hash| Task.new(task_hash) }
            end
          end
        end
      end
    end
  end
end
