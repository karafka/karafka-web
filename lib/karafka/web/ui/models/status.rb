# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Model that represents the general status of the Web UI.
        # We use this data to display a status page that helps with debugging on what is missing
        # in the overall setup of the Web UI.
        #
        # People have various problems like too many partitions, not created topics, etc. and this
        # data and view aims to help them with understanding the current status of the setup
        class Status
          # Status of a single step of setup
          Step = Struct.new(:status, :details) do
            # @return [Boolean] is the given step successfully configured and working
            def success?
              status == :success
            end

            # @return [String] stringified status
            def to_s
              status.to_s
            end
          end

          # Initializes the status object and tries to connect to Kafka
          def initialize
            connect
          end

          # @return [Status::Step] were we able to connect to Kafka or not
          def connection
            Step.new(
              @connected ? :success : :failure,
              nil
            )
          end

          # @return [Status::Step] do all the needed topics exist
          def topics
            if connection.success?
              details = topics_details
              status = details.all? { |_, detail| detail[:present] } ? :success : :failure
            else
              status = :halted
              details = {}
            end

            Step.new(
              status,
              details
            )
          end

          # @return [Status::Step] do we have all topics with expected number of partitions
          def partitions
            if topics.success?
              status = :success
              status = :failure if topics_details[topics_consumers_states][:partitions] != 1
              status = :failure if topics_details[topics_consumers_reports][:partitions] != 1
              details = topics_details
            else
              status = :halted
              details = {}
            end

            Step.new(
              status,
              details
            )
          end

          # @return [Status::Step] Is the initial state present in the setup or not
          def initial_state
            if partitions.success?
              @current_state ||= Models::State.current
              status = @current_state ? :success : :failure
            else
              status = :halted
            end

            Step.new(
              status,
              nil
            )
          end

          # @return [Status::Step] Is there at least one active karafka server reporting to the
          #   Web UI
          def live_reporting
            if initial_state.success?
              @processes ||= Models::Processes.active(@current_state)
              status = @processes.empty? ? :failure : :success
            else
              status = :halted
            end

            Step.new(
              status,
              nil
            )
          end

          # @return [Status::Step] is there a subscription to our reports topic that is being
          #   consumed actively.
          def state_calculation
            if live_reporting.success?
              @subscriptions ||= Models::Health.current(@current_state).values.flat_map(&:keys)
              status = @subscriptions.include?(topics_consumers_reports) ? :success : :failure
            else
              status = :halted
            end

            Step.new(
              status,
              nil
            )
          end

          # @return [Status::Step] is Pro enabled with all of its features.
          # @note It's not an error not to have it but we want to warn, that some of the features
          #   may not work without Pro.
          def pro_subscription
            status = if state_calculation.success?
                       ::Karafka.pro? ? :success : :warning
                     else
                       :halted
                     end

            Step.new(
              status,
              nil
            )
          end

          private

          # @return [String] consumers states topic name
          def topics_consumers_states
            ::Karafka::Web.config.topics.consumers.states.to_s
          end

          # @return [String] consumers reports topic name
          def topics_consumers_reports
            ::Karafka::Web.config.topics.consumers.reports.to_s
          end

          # @return [String] errors topic name
          def topics_errors
            ::Karafka::Web.config.topics.errors
          end

          # @return [Hash] hash with topics with which we work details (even if don't exist)
          def topics_details
            topics = {
              topics_consumers_states => { present: false, partitions: 0 },
              topics_consumers_reports => { present: false, partitions: 0 },
              topics_errors => { present: false, partitions: 0 }
            }

            @cluster_info.topics.each do |topic|
              name = topic[:topic_name]

              next unless topics.key?(name)

              topics[name][:present] = true
              topics[name][:partitions] = topic[:partition_count]
            end

            topics
          end

          # Tries connecting with the cluster and sets the connection state
          def connect
            @cluster_info = ::Karafka::Admin.cluster_info
            @connected = true
          rescue ::Rdkafka::RdkafkaError
            @connected = false
          end
        end
      end
    end
  end
end
