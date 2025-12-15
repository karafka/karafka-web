# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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
          SCHEMA_VERSION = '1.2.0'

          class << self
            # Dispatches the command request
            #
            # @param command_name [String, Symbol] name of the command we want to deal with in the
            #   process
            # @param process_id [String] id of the process. We use name instead of id only
            #   because in the web ui we work with the full name and it is easier.
            # @param params [Hash] hash with extra command params that some commands may use.
            # @param matchers [Hash] optional hash with matching criteria for filtering which
            #   processes should handle this command. Supported keys:
            #   - :consumer_group_id [String] - only processes with this consumer group
            #   - :topic [String] - only processes consuming this topic (future use)
            def request(command_name, process_id, params = {}, matchers: {})
              payload = {
                schema_version: SCHEMA_VERSION,
                type: 'request',
                # Name is auto-generated and required. Should not be changed
                command: params.merge(name: command_name),
                dispatched_at: Time.now.to_f,
                process: {
                  id: process_id
                }
              }

              # Only include matchers if there are any - keeps payload clean for simple commands
              payload[:matchers] = matchers unless matchers.empty?

              produce(process_id, 'request', payload)
            end

            # Dispatches the acceptance info. Indicates that a command was received and appropriate
            # action will be taken but async. Useful for commands that may not take immediate
            # actions upon receiving a command.
            #
            # @param command_name [String, Symbol] command that triggered this result
            # @param process_id [String] related process id
            # @param params [Hash] input command params (or empty hash if none)
            def acceptance(command_name, process_id, params = {})
              produce(
                process_id,
                'acceptance',
                {
                  schema_version: SCHEMA_VERSION,
                  type: 'acceptance',
                  command: params.merge(name: command_name),
                  dispatched_at: Time.now.to_f,
                  process: {
                    id: process_id
                  }
                }
              )
            end

            # Dispatches the result request
            #
            # @param command_name [String, Symbol] command that triggered this result
            # @param process_id [String] related process id
            # @param result [Object] anything that can be the result of the command execution
            def result(command_name, process_id, result)
              produce(
                process_id,
                'result',
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
              ::Karafka::Web.config.topics.consumers.commands.name
            end

            # Converts payload to json, compresses it and dispatches to Kafka
            #
            # @param process_id [String]
            # @param type [String] type of the request
            # @param payload [Hash] hash with payload
            def produce(process_id, type, payload)
              producer.produce_async(
                topic: commands_topic,
                key: process_id,
                partition: 0,
                payload: ::Zlib::Deflate.deflate(payload.to_json),
                headers: {
                  'zlib' => 'true',
                  'type' => type
                }
              )
            end
          end
        end
      end
    end
  end
end
