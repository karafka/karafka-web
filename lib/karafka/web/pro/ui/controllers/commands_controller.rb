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
          class CommandsController < BaseController
            def index
              @watermark_offsets = Models::WatermarkOffsets.find(commands_topic, 0)

              previous_offset, @command_messages, next_offset = current_partition_data

              paginate(
                previous_offset,
                @params.current_offset,
                next_offset,
                # If message is an array, it means it's a compacted dummy offset representation
                @command_messages.map { |message| message.is_a?(Array) ? message.last : message.offset }
              )

              render
            end

            def show(offset)
              @command_message = Models::Message.find(
                commands_topic,
                0,
                offset
              )

              render
            end

            def recent
              @watermark_offsets = Models::WatermarkOffsets.find(commands_topic, 0)

              show(@watermark_offsets.high - 1)
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

            def commands_topic
              ::Karafka::Web.config.topics.consumers.commands
            end
          end
        end
      end
    end
  end
end
