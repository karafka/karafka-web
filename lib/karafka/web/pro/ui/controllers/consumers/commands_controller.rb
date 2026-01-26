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
      module Ui
        module Controllers
          module Consumers
            # Controller for viewing details of dispatched commands and their results
            class CommandsController < BaseController
              # Lists commands from the consumers commands topic
              def index
                features.commanding!

                @schema_version = Commanding::Dispatcher::SCHEMA_VERSION
                @watermark_offsets = Models::WatermarkOffsets.find(commands_topic, 0)

                previous_offset, @command_messages, next_offset = current_partition_data

                # If message is an array, it means it's a compacted dummy offset representation
                mapped_messages = @command_messages.map do |message|
                  message.is_a?(Array) ? message.last : message.offset
                end

                paginate(
                  previous_offset,
                  @params.current_offset,
                  next_offset,
                  mapped_messages
                )

                render
              end

              # Shows details about given command / result
              #
              # @param offset [Integer] offset of the command message we're interested in
              def show(offset)
                features.commanding!

                @schema_version = Commanding::Dispatcher::SCHEMA_VERSION
                @command_message = Models::Message.find(
                  commands_topic,
                  0,
                  offset
                )

                render
              end

              # Displays the most recent available command message details
              def recent
                features.commanding!

                # We read 25 just in case there would be a lot of transactional noise
                messages = ::Karafka::Admin.read_topic(commands_topic, 0, 25)

                # We find the most recent (last since they are shipped in reverse order)
                recent = messages.reverse.find { |message| !message.is_a?(Array) }

                return show(recent.offset) if recent

                # If nothing found, lets redirect user back to the commands list
                redirect(
                  "commands",
                  warning: "No recent commands available"
                )
              end

              private

              # @return [Array] Array with requested messages as well as pagination details
              #   and other obtained metadata
              def current_partition_data
                Models::Message.offset_page(
                  commands_topic,
                  0,
                  @params.current_offset,
                  @watermark_offsets
                )
              end

              # @return [String] consumers commands topic name
              def commands_topic
                ::Karafka::Web.config.topics.consumers.commands.name
              end
            end
          end
        end
      end
    end
  end
end
