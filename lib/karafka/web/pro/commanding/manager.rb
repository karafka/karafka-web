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
              iterator.stop if @stop
              next if @stop
              next unless message
              next unless matches?(message)

              control(message)
            rescue => e
              report_error(e)

              sleep(c_config.pause_timeout)

              next
            end
          rescue => e
            return if done?

            report_error(e)

            sleep(c_config.pause_timeout)

            retry
          end

          def control(message)
            case message.payload[:command][:name]
            when 'probe'
              probe
            when 'stop'
              ::Process.kill('QUIT', ::Process.pid)
            when 'quiet'
              ::Process.kill('TSTP', ::Process.pid)
            end
          end

          def probe
            threads = {}

            Thread.list.each do |thread|
              tid = (thread.object_id ^ ::Process.pid).to_s(36)

              t = threads[tid] = {}

              t[:label] = "Thread TID-#{tid} #{thread.name}"

              if thread.backtrace
                t[:backtrace] = thread.backtrace.join("\n")
              else
                t[:backtrace] = '<no backtrace available>'
              end
            end

            Dispatcher.result(threads, process_id, 'probe')
          end

          def matches?(message)
            return false unless message.payload[:type] == 'command'
            return true if message.key == '*'
            return true if message.key == process_id
            return false unless message.payload[:schema_version] == '0.0.1'

            false
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
