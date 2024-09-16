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
      # Namespace for things related to consumers commanding (management)
      #
      # This feature allows for basic of consumers. They can be stopped, moved to quiet or traced
      # via the Web UI
      module Commanding
        # Wrapper around the Pro Iterator that yields messages with commands when needed for
        # further processing.
        #
        # This iterator supports error handling, basically on errors it will be reported and
        # ignored as long as they are not critical. Critical errors will cause back-off and
        # reconnection.
        class Listener
          # Runs iterator and keeps it running until not needed.
          #
          # @yield [Karafka::Messages::Message] command message
          def each
            c_config = ::Karafka::Web.config.commanding
            t_config = Karafka::Web.config.topics

            iterator = Karafka::Pro::Iterator.new(
              { t_config.consumers.commands => true },
              settings: c_config.kafka,
              yield_nil: true,
              max_wait_time: c_config.max_wait_time
            )

            iterator.each do |message|
              iterator.stop if @stop
              next if @stop
              next unless message

              yield(message)
            rescue StandardError => e
              report_error(e)

              sleep(c_config.pause_timeout / 1_000)

              next
            end
          rescue StandardError => e
            report_error(e)

            return if done?

            sleep(c_config.pause_timeout / 1_000)

            retry
          end

          # Triggers stop of the listener. Does **not** stop the listener but requests it to stop.
          def stop
            @stop = true
          end

          private

          # @return [Boolean] true if we should stop
          def done?
            @stop
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
        end
      end
    end
  end
end
