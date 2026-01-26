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
        module Handlers
          # Namespace for commands related to specific partitions
          module Partitions
            # Namespace for partitions related commands
            module Commands
              # Base class for all the partition related commands handlers
              class Base
                # @param listener [Karafka::Connection::Listener] listener that handles given
                #   partition in the context of given subscription group
                # @param client [Karafka::Connection::Client] underlying Kafka client
                # @param request [Request] command request
                def initialize(listener, client, request)
                  @listener = listener
                  @client = client
                  @request = request
                end

                # Runs the command
                def call
                  raise NotImplementedError, "Implement in a subclass"
                end

                private

                attr_reader :listener, :client, :request

                # @return [String] name of the topic on which the command should be applied
                def topic
                  @topic ||= request[:topic]
                end

                # @return [String] partition for which the command should be applied
                def partition_id
                  @partition_id ||= request[:partition_id]
                end

                # @return [Karafka::Processing::Coordinator, Karafka::Pro::Processing::Coordinator]
                def coordinator
                  @coordinator ||= listener.coordinators.find_or_create(topic, partition_id)
                end

                # Publishes the execution result back to Kafka
                # @param status [String] execution status
                def result(status)
                  Commanding::Dispatcher.result(
                    request.name,
                    ::Karafka::Web.config.tracking.consumers.sampler.process_id,
                    request.to_h.merge(status: status)
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
