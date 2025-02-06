# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        # Manager responsible for receiving commands and taking appropriate actions
        # It uses the assign API instead of subscribe and it does NOT publish or change anything
        # Since its subscription is not user-related and does not run any work in the workers, it
        # is not visible in the statistics.
        #
        # There are few critical things here worth keeping in mind:
        #   - We do **not** use dynamic routing here and we do not inject active consumption
        #   - We use a direct assign API to get an "invisible" (from the end user) perspective
        #     connection to the commands topic for management. This is done that way so the end
        #     user does not see this connection within the UI as it should not be a manageable one
        #     anyhow. Also, on top of that, because we handle it under the hood, this is also not
        #     prone to saturation and other issues that can arise when working under stress. Thanks
        #     to that, probing can be handled almost immediately on command arrival.
        #   - Messages causing errors will be ignored and won't block.
        #   - Any errors are reported back to the Karafka monitor pipeline.
        class Manager
          include ::Karafka::Helpers::Async
          include Singleton

          def initialize
            @listener = Listener.new
            @matcher = Matcher.new
          end

          # When app starts to run, we start to listen for commands
          #
          # @param _event [Karafka::Core::Monitoring::Event]
          def on_app_running(_event)
            async_call('karafka.web.pro.commanding.manager')
          end

          # When app stops, we stop the manager
          #
          # @param _event [Karafka::Core::Monitoring::Event]
          def on_app_stopping(_event)
            @listener.stop
          end

          # This ensures that in case of super fast shutdown, we wait on this in case it would be
          # slower not to end up with a semi-closed iterator.
          #
          # @param _event [Karafka::Core::Monitoring::Event]
          def on_app_stopped(_event)
            @thread&.join
          end

          private

          # Main iterator code.
          # This iterator listens to the commands topic and when it detects messages targeting
          # current process, performs the requested command.
          def call
            @listener.each do |message|
              next unless @matcher.matches?(message)

              control(
                Request.new(message.payload[:command])
              )
            end
          end

          # Runs the expected command
          #
          # @param command [Request] command request
          def control(command)
            action = case command.name
                     when Commands::Consumers::Trace.name
                       Commands::Consumers::Trace
                     when Commands::Consumers::Stop.name
                       Commands::Consumers::Stop
                     when Commands::Consumers::Quiet.name
                       Commands::Consumers::Quiet
                     when Commands::Partitions::Seek.name
                       Commands::Partitions::Seek
                     when Commands::Partitions::Resume.name
                       Commands::Partitions::Resume
                     when Commands::Partitions::Pause.name
                       Commands::Partitions::Pause
                     else
                       # We raise it and will be rescued, reported and ignored. We raise it as
                       # this should not happen unless there are version conflicts
                       raise ::Karafka::Errors::UnsupportedCaseError, command.name
                     end

            action.new(command).call
          end
        end
      end
    end
  end
end
