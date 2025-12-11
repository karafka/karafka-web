# frozen_string_literal: true

# Load status components
require_relative 'status/step'
require_relative 'status/context'
require_relative 'status/checks/base'

# Load all check classes
Dir[File.join(__dir__, 'status', 'checks', '*.rb')].each { |file| require file }

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
        # data and view aims to help them with understanding the current status of the setup.
        #
        # The Status model uses a DSL-based architecture where each check is a separate class
        # that declares its dependencies and behavior. This makes the code more maintainable,
        # testable, and easier to extend.
        #
        # @example Basic usage
        #   status = Status.new
        #   status.enabled        #=> Status::Step
        #   status.connection     #=> Status::Step
        #
        # @example Check result
        #   result = status.enabled
        #   result.success?       #=> true or false
        #   result.status         #=> :success, :warning, :failure, or :halted
        #   result.details        #=> { ... } or []
        class Status
          # Registry of all check classes in execution order.
          #
          # The order matters because checks depend on previous checks in the chain.
          # Independent checks (like pro_subscription) are placed at the end.
          CHECKS = {
            enabled: Checks::Enabled,
            connection: Checks::Connection,
            topics: Checks::Topics,
            partitions: Checks::Partitions,
            replication: Checks::Replication,
            initial_consumers_state: Checks::InitialConsumersState,
            initial_consumers_metrics: Checks::InitialConsumersMetrics,
            consumers_reports: Checks::ConsumersReports,
            live_reporting: Checks::LiveReporting,
            consumers_schemas: Checks::ConsumersSchemas,
            materializing_lag: Checks::MaterializingLag,
            state_calculation: Checks::StateCalculation,
            consumers_reports_schema_state: Checks::ConsumersReportsSchemaState,
            routing_topics_presence: Checks::RoutingTopicsPresence,
            pro_subscription: Checks::ProSubscription
          }.freeze

          # Initializes a new Status instance.
          #
          # Creates a shared context for all checks and initializes the results cache.
          def initialize
            @context = Context.new
            @results = {}
          end

          # Define methods for each check that delegate to the runner
          CHECKS.each_key do |check_name|
            define_method(check_name) do
              @results[check_name] ||= execute_check(check_name)
            end
          end

          private

          # Executes a check and handles dependency halting.
          #
          # If a check has a dependency and that dependency failed, the check is halted.
          #
          # @param name [Symbol] the check name
          # @return [Step] the check result
          def execute_check(name)
            check_class = CHECKS[name]

            # Handle dependency chain - independent checks skip this
            if !check_class.independent? && (dependency = check_class.dependency)
              dependency_result = send(dependency)

              # If dependency failed, halt this check
              return Step.new(:halted, check_class.halted_details) unless dependency_result.success?
            end

            # Execute the actual check
            check_class.new(@context).call
          end
        end
      end
    end
  end
end
