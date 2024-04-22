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
        # Dispatcher for sending commanding related messages. Those can be:
        # - command (do something)
        # - result (you wanted me to get you some info, here it is)
        #
        # Dispatcher requires Web UI to have a producer
        class Dispatcher
          # What schema do we have in current Karafka version for commands dispatches
          SCHEMA_VERSION = '1.0.0'

          class << self
            # Dispatches the command request
            #
            # @param name [String, Symbol] name of the command we want to deal with in the process
            # @param process_id [String] id of the process. We use name instead of id only
            #   because in the web ui we work with the full name and it is easier. Since
            def command(name, process_id)
              produce(
                process_id,
                {
                  schema_version: SCHEMA_VERSION,
                  type: 'command',
                  command: {
                    name: name
                  },
                  dispatched_at: Time.now.to_f,
                  process: {
                    id: process_id
                  }
                }
              )
            end

            # Dispatches the result request
            #
            # @param result [Object] anything that can be the result of the command execution
            # @param process_id [String] related process id
            # @param command_name [String, Symbol] command that triggered this result
            def result(result, process_id, command_name)
              produce(
                process_id,
                {
                  schema_version: SCHEMA_VERSION,
                  type: 'result',
                  command: {
                    name: command_name
                  },
                  result: result,
                  dispatched_at: Time.now.to_f,
                  process: {
                    id: process_id
                  }
                }
              )
            end

            private

            # @return [::WaterDrop::Producer] web ui producer
            def producer
              Karafka::Web.producer
            end

            # @return [String] consumers commands topic
            def commands_topic
              ::Karafka::Web.config.topics.consumers.commands
            end

            # Converts payload to json, compresses it and dispatches to Kafka
            #
            # @param payload [Hash] hash with payload
            # @param process_id [String]
            def produce(process_id, payload)
              producer.produce_async(
                topic: commands_topic,
                key: process_id,
                partition: 0,
                payload: ::Zlib::Deflate.deflate(payload.to_json),
                headers: { 'zlib' => 'true' }
              )
            end
          end
        end
      end
    end
  end
end
