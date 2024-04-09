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
      module Ui
        module Controllers
          # Controller for viewing details of dispatched commands and their results
          class CommandsController < BaseController
            # Lists commands from the consumers commands topic
            def index
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
              # We read 25 just in case there would be a lot of transactional noise
              messages = ::Karafka::Admin.read_topic(commands_topic, 0, 25)

              # We find the most recent (last since they are shipped in reverse order)
              recent = messages.reverse.find { |message| !message.is_a?(Array) }

              return show(recent.offset) if recent

              # If nothing found, lets redirect user back to the commands list
              redirect(
                'commands',
                warning: 'No recent commands available.'
              )
            end

            private

            # @return [Array] Array with requested messages as well as pagination details and other
            #   obtained metadata
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
              ::Karafka::Web.config.topics.consumers.commands
            end
          end
        end
      end
    end
  end
end
