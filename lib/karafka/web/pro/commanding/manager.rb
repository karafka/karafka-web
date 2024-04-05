# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

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

          # When app starts to run, we start to manage for commands
          #
          # @param _event [Karafka::Core::Monitoring::Event]
          def on_app_running(_event)
            async_call('karafka.web.pro.commanding.manager')
          end

          # When app stops, we stop the manager
          #
          # @param _event [Karafka::Core::Monitoring::Event]
          def on_app_stopping(_event)
            @stop = true
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
            c_config = ::Karafka::Web.config.commanding
            t_config = Karafka::Web.config.topics

            iterator = Karafka::Pro::Iterator.new(
              { t_config.consumers.commands => true },
              settings: c_config.kafka.merge('group.id' => c_config.consumer_group),
              yield_nil: true,
              max_wait_time: c_config.max_wait_time
            )

            iterator.each do |message|
              begin
                iterator.stop if @stop
                next if @stop
                next unless message
                next unless matches?(message)

                control(message.payload[:command][:name])
              rescue StandardError => e
                report_error(e)

                sleep(c_config.pause_timeout / 1_000)

                next
              end
            end
          rescue StandardError => e
            return if done?

            report_error(e)

            sleep(c_config.pause_timeout / 1_000)

            retry
          end

          # Runs the expected command
          #
          # @param command [String] command expected to run
          def control(command)
            case command
            when 'probe'
              probe
            when 'stop'
              ::Process.kill('QUIT', ::Process.pid)
            when 'quiet'
              ::Process.kill('TSTP', ::Process.pid)
            end
          end

          # Collects all backtraces from the available Ruby threads and publishes their details
          #   back to Kafka for debug.
          def probe
            threads = {}

            Thread.list.each do |thread|
              tid = (thread.object_id ^ ::Process.pid).to_s(36)
              t_d = threads[tid] = {}
              t_d[:label] = "Thread TID-#{tid} #{thread.name}"
              t_d[:backtrace] = (thread.backtrace || ['<no backtrace available>']).join("\n")
            end

            Dispatcher.result(threads, process_id, 'probe')
          end

          # @param message [Karafka::Messages::Message] message with command
          # @return [Boolean] is this message dedicated to current process and is actionable
          def matches?(message)
            matches = true

            # We want to work only with commands that target all processes or our current
            matches = false unless message.key == '*' || message.key == process_id
            # We operate only on commands. Result messages should be ignored
            matches = false unless message.payload[:type] == 'command'
            # Ignore messages that have different schema. This can happen in the middle of
            # upgrades of the framework. We ignore this not to risk compatibility issues
            matches = false unless message.payload[:schema_version] == Dispatcher::SCHEMA_VERSION

            matches
          end

          # Reports any error that occurred in the manager
          #
          # Since we have an iterator based Kafka connection here, we do not have standard Karafka
          # error handling and retries. This means, that we have to handle errors ourselves and
          # report them to the instrumentation pipeline.
          #
          # @param error [StandardError] any error that occurred in the manager
          def report_error(error)
            ::Karafka.monitor.instrument(
              'error.occurred',
              error: error,
              caller: self,
              type: 'web.controlling.controller.error'
            )
          end

          # @return [String] current process id
          def process_id
            @process_id ||= ::Karafka::Web.config.tracking.consumers.sampler.process_id
          end
        end
      end
    end
  end
end
