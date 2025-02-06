# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for request.

module Karafka
  module Web
    module Pro
      module Commanding
        # Namespace for handlers that deal with executing in async (outside of the request cycle)
        # the requested commands.
        module Handlers
          # Namespace for handling requests related to consuming Kafka topics partitions
          module Partitions
            # Selects proper command for running prior to next poll and executes its flow
            class Executor
              # @param listener [Karafka::Connection::Listener]
              # @param client [Karafka::Connection::Client]
              # @param request [Request]
              def call(listener, client, request)
                command = case request.name
                          when Commanding::Commands::Partitions::Resume.name
                            Commands::Resume
                          when Commanding::Commands::Partitions::Pause.name
                            Commands::Pause
                          when Commanding::Commands::Partitions::Seek.name
                            Commands::Seek
                          else
                            raise ::Karafka::Errors::UnsupportedCaseError, request.name
                          end

                command.new(
                  listener,
                  client,
                  request
                ).call
              end

              # Publishes the reject event as the final result. Used to indicate, that given
              # request will not be processed because it is not valid anymore.
              #
              # @param request [Request]
              def reject(request)
                Dispatcher.result(
                  request.name,
                  process_id,
                  request.to_h.merge(status: 'rebalance_rejected')
                )
              end
            end
          end
        end
      end
    end
  end
end
