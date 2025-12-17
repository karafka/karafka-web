# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Handlers
          module Topics
            # Selects proper command for running prior to next poll and executes its flow
            class Executor
              # @param listener [Karafka::Connection::Listener]
              # @param client [Karafka::Connection::Client]
              # @param request [Request]
              def call(listener, client, request)
                command = case request.name
                          when Commanding::Commands::Topics::Resume.name
                            Commands::Resume
                          when Commanding::Commands::Topics::Pause.name
                            Commands::Pause
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

              private

              # @return [String] id of the current consumer process
              def process_id
                ::Karafka::Web.config.tracking.consumers.sampler.process_id
              end
            end
          end
        end
      end
    end
  end
end
