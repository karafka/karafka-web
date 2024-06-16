# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Model that represents the general status of the Web UI.
        #
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
              status == :success || status == :warning
            end

            # @return [String] local namespace for partial of a given type
            def partial_namespace
              case status
              when :success then 'successes'
              when :warning then 'warnings'
              when :failure then 'failures'
              when :halted  then 'failures'
              else
                raise ::Karafka::Errors::UnsupportedCaseError, status
              end
            end

            # @return [String] stringified status
            def to_s
              status.to_s
            end
          end

          # Is karafka-web enabled in the `karafka.rb`
          # Checks if the consumer group for web-ui is injected.
          # It does **not** check if the group is active because this may depend on the
          # configuration details, but for the Web-UI web app to work, the routing needs to be
          # aware of the deserializer, etc
          def enabled
            enabled = ::Karafka::App.routes.map(&:name).include?(
              ::Karafka::Web.config.group_id
            )

            Step.new(
              enabled ? :success : :failure,
              nil
            )
          end

          # @return [Status::Step] were we able to connect to Kafka or not and how fast.
          # Some people try to work with Kafka over the internet with really high latency and this
          # should be highlighted in the UI as often the connection just becomes unstable
          def connection
            if enabled.success?
              # Do not connect more than once during the status object lifetime
              @connection_time || connect

              level = if @connection_time < 1_000
                        :success
                      elsif @connection_time < 1_000_000
                        :warning
                      else
                        :failure
                      end
            else
              level = :halted
            end

            Step.new(
              level,
              { time: @connection_time }
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
              status = :failure if topics_details[topics_consumers_metrics][:partitions] != 1
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

          # @return [Status::Step] do we have correct replication for given env
          def replication
            if partitions.success?
              status = :success
              # low replication is not an error but just a warning and a potential problem
              # in case of a crash, this is why we do not fail but warn only
              status = :warning if topics_details.values.any? { |det| det[:replication] < 2 }
              # Allow for non-production setups to use replication 1 as it is not that relevant
              status = :success unless Karafka.env.production?
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

          # @return [Status::Step] Is the initial consumers state present in Kafka and that they
          #   can be deserialized
          def initial_consumers_state
            details = { issue_type: :presence }

            if replication.success?
              begin
                @current_state ||= Models::ConsumersState.current
                status = @current_state ? :success : :failure
              rescue JSON::ParserError
                status = :failure
                details[:issue_type] = :deserialization
              end
            else
              status = :halted
            end

            Step.new(
              status,
              details
            )
          end

          # @return [Status::Step] Is the initial consumers metrics record present in Kafka and
          #   that they can be deserialized
          def initial_consumers_metrics
            details = { issue_type: :presence }

            if initial_consumers_state.success?
              begin
                @current_metrics ||= Models::ConsumersMetrics.current
                status = @current_metrics ? :success : :failure
              rescue JSON::ParserError
                status = :failure
                details[:issue_type] = :deserialization
              end
            else
              status = :halted
            end

            Step.new(
              status,
              details
            )
          end

          # @return [Status::Step] could we read and operate on the current processes data (if any)
          def consumers_reports
            if initial_consumers_metrics.success?
              @processes ||= Models::Processes.active(@current_state)
              status = :success
            else
              status = :halted
            end

            Step.new(status, nil)
          rescue JSON::ParserError
            Step.new(:failure, nil)
          end

          # @return [Status::Step] Is there at least one active karafka server reporting to the
          #   Web UI
          def live_reporting
            status = if consumers_reports.success?
                       @processes.empty? ? :failure : :success
                     else
                       :halted
                     end

            Step.new(
              status,
              nil
            )
          end

          # @return [Status::Step] Is there a significant lag in the reporting of aggregated data
          #   back to the Kafka. If yes, it means that the results in the Web UI will be delayed
          #   against the reality. Often it means, that there is over-saturation on the consumer
          #   that is materializing the states.
          #
          # @note Since both states and metrics are reported together, it is enough for us to check
          #   on one of them.
          def materializing_lag
            max_lag = (Web.config.tracking.interval * 2) / 1_000

            details = { lag: 0, max_lag: max_lag }

            status = if live_reporting.success?
                       lag = Time.now.to_f - @current_state.dispatched_at
                       details[:lag] = lag

                       lag > max_lag ? :failure : :success
                     else
                       :halted
                     end

            Step.new(
              status,
              details
            )
          end

          # @return [Status::Step] is there a subscription to our reports topic that is being
          #   consumed actively.
          def state_calculation
            if materializing_lag.success?
              @subscriptions ||= Models::Health
                                 .current(@current_state)
                                 .values.map { |consumer_group| consumer_group[:topics] }
                                 .flat_map(&:keys)

              status = @subscriptions.include?(topics_consumers_reports) ? :success : :failure
            else
              status = :halted
            end

            Step.new(
              status,
              nil
            )
          end

          # @return [Status::Step] Are we able to actually digest the consumers reports with the
          #   consumer that is consuming them.
          def consumers_reports_schema_state
            status = if state_calculation.success?
                       @current_state[:schema_state] == 'compatible' ? :success : :failure
                     else
                       :halted
                     end

            Step.new(
              status,
              nil
            )
          end

          # @return [Status::Step] are there any active topics in the routing that are not present
          #   in the cluster (does not apply to patterns)
          def routing_topics_presence
            if consumers_reports_schema_state.success?
              existing = @cluster_info.topics.map { |topic| topic[:topic_name] }

              missing = ::Karafka::App
                        .routes
                        .flat_map(&:topics)
                        .flat_map { |topics| topics.map(&:itself) }
                        .select(&:active?)
                        .reject { |topic| topic.respond_to?(:patterns?) ? topic.patterns? : false }
                        .map(&:name)
                        .uniq
                        .then { |routed_topics| routed_topics - existing }

              Step.new(missing.empty? ? :success : :warning, missing)
            else
              Step.new(:halted, [])
            end
          end

          # @return [Status::Step] is Pro enabled with all of its features.
          # @note It's not an error not to have it but we want to warn, that some of the features
          #   may not work without Pro.
          def pro_subscription
            Step.new(
              ::Karafka.pro? ? :success : :warning,
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

          # @return [String] consumers metrics topic name
          def topics_consumers_metrics
            ::Karafka::Web.config.topics.consumers.metrics.to_s
          end

          # @return [String] errors topic name
          def topics_errors
            ::Karafka::Web.config.topics.errors
          end

          # @return [Hash] hash with topics with which we work details (even if don't exist)
          def topics_details
            base = { present: false, partitions: 0, replication: 1 }

            topics = {
              topics_consumers_states => base.dup,
              topics_consumers_reports => base.dup,
              topics_consumers_metrics => base.dup,
              topics_errors => base.dup
            }

            @cluster_info.topics.each do |topic|
              name = topic[:topic_name]

              next unless topics.key?(name)

              topics[name].merge!(
                present: true,
                partitions: topic[:partition_count],
                replication: topic[:partitions].map { |part| part[:replica_count] }.max
              )
            end

            topics
          end

          # Tries connecting with the cluster and saves the cluster info and the connection time
          # @note If fails, `connection_time` will be 1_000_000
          def connect
            started = Time.now.to_f
            # For status we always need uncached data, otherwise status could cache outdated
            # info
            @cluster_info = Models::ClusterInfo.fetch(cached: false)
            @connection_time = (Time.now.to_f - started) * 1_000
          rescue ::Rdkafka::RdkafkaError
            @connection_time = 1_000_000
          end
        end
      end
    end
  end
end
