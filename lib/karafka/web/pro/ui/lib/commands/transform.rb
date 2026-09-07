# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          module Commands
            # Builds the commanding request out of a typed hash (the URL scope merged with the
            # normalized form data). Each method returns a `{ name:, payload:, matchers: }` hash
            # that {Dispatcher} hands over to {Commanding::Dispatcher.request}.
            module Transform
              # Seconds the user enters are converted to milliseconds for the pause commands
              MILLIS_IN_SECOND = 1_000

              private_constant :MILLIS_IN_SECOND

              class << self
                # @param data [Hash] scope (`consumer_group_id`, `topic`, `partition_id`) merged
                #   with the normalized seek form data
                # @return [Hash] partition seek command
                def partition_seek(data)
                  {
                    name: Commanding::Commands::Partitions::Seek.name,
                    payload: {
                      consumer_group_id: data[:consumer_group_id],
                      topic: data[:topic],
                      partition_id: data[:partition_id],
                      offset: data[:offset],
                      prevent_overtaking: data[:prevent_overtaking],
                      force_resume: data[:force_resume]
                    },
                    matchers: partition_matchers(data)
                  }
                end

                # @param data [Hash] scope merged with the normalized pause form data
                # @return [Hash] partition pause command
                def partition_pause(data)
                  {
                    name: Commanding::Commands::Partitions::Pause.name,
                    payload: {
                      consumer_group_id: data[:consumer_group_id],
                      topic: data[:topic],
                      partition_id: data[:partition_id],
                      duration: data[:duration] * MILLIS_IN_SECOND,
                      prevent_override: data[:prevent_override]
                    },
                    matchers: partition_matchers(data)
                  }
                end

                # @param data [Hash] scope merged with the normalized resume form data
                # @return [Hash] partition resume command
                def partition_resume(data)
                  {
                    name: Commanding::Commands::Partitions::Resume.name,
                    payload: {
                      consumer_group_id: data[:consumer_group_id],
                      topic: data[:topic],
                      partition_id: data[:partition_id],
                      reset_attempts: data[:reset_attempts]
                    },
                    matchers: partition_matchers(data)
                  }
                end

                # @param data [Hash] scope (`consumer_group_id`, `topic`) merged with the
                #   normalized pause form data
                # @return [Hash] topic pause command (all partitions of the topic)
                def topic_pause(data)
                  {
                    name: Commanding::Commands::Topics::Pause.name,
                    payload: {
                      consumer_group_id: data[:consumer_group_id],
                      topic: data[:topic],
                      duration: data[:duration] * MILLIS_IN_SECOND,
                      prevent_override: data[:prevent_override]
                    },
                    matchers: topic_matchers(data)
                  }
                end

                # @param data [Hash] scope merged with the normalized resume form data
                # @return [Hash] topic resume command (all partitions of the topic)
                def topic_resume(data)
                  {
                    name: Commanding::Commands::Topics::Resume.name,
                    payload: {
                      consumer_group_id: data[:consumer_group_id],
                      topic: data[:topic],
                      reset_attempts: data[:reset_attempts]
                    },
                    matchers: topic_matchers(data)
                  }
                end

                private

                # @param data [Hash]
                # @return [Hash] matchers scoping a command to a single partition
                def partition_matchers(data)
                  {
                    consumer_group_id: data[:consumer_group_id],
                    topic: data[:topic],
                    partition_id: data[:partition_id]
                  }
                end

                # @param data [Hash]
                # @return [Hash] matchers scoping a command to a whole topic
                def topic_matchers(data)
                  {
                    consumer_group_id: data[:consumer_group_id],
                    topic: data[:topic]
                  }
                end
              end
            end
          end
        end
      end
    end
  end
end
