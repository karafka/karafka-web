# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

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
                  request.to_h.merge(status: "rebalance_rejected")
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
