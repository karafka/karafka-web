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
        module Controllers
          module Explorer
            # Controller for working with messages
            # While part of messages operations is done via explorer (exploring), this controller
            # handles other cases not related to viewing data
            class MessagesController < BaseController
              # Renders a form allowing for piping a message to a different topic
              #
              # @param topic_id [String]
              # @param partition_id [Integer]
              # @param offset [Integer] offset of the message we want to republish
              def forward(topic_id, partition_id, offset)
                @message = Models::Message.find(topic_id, partition_id, offset)

                deny! unless visibility_filter.republish?(@message)

                @topic_id = topic_id
                @partition_id = partition_id
                @offset = offset

                @target_topic = @topic_id
                @target_partition = @partition_id

                @topics = Models::ClusterInfo
                  .topics
                  .sort_by { |topic| topic[:topic_name] }

                unless ::Karafka::Web.config.ui.visibility.internal_topics
                  @topics.reject! { |topic| topic[:topic_name].start_with?("__") }
                end

                render
              end

              # Takes a requested message content and republishes it again
              #
              # @param topic_id [String]
              # @param partition_id [Integer]
              # @param offset [Integer] offset of the message we want to republish
              def republish(topic_id, partition_id, offset)
                forward(topic_id, partition_id, offset)

                dispatch_message = {
                  topic: params.str(:target_topic),
                  payload: @message.raw_payload,
                  headers: @message.headers.dup,
                  key: @message.key
                }

                # Add target partition only if it was requested, otherwise it will use either the
                # message key (if present) or will jut round-robin
                unless params.fetch(:target_partition).empty?
                  dispatch_message[:partition] = params.int(:target_partition)
                end

                # Include source headers for enhanced debuggability
                if params.bool(:include_source_headers)
                  dispatch_message[:headers].merge!(
                    "source_topic" => @message.topic,
                    "source_partition" => @message.partition.to_s,
                    "source_offset" => @message.offset.to_s
                  )
                end

                delivery = ::Karafka::Web.producer.produce_sync(dispatch_message)

                redirect(
                  :previous,
                  success: republished(@message, delivery)
                )
              end

              # Renders a form allowing for publishing a brand new message to a given topic
              #
              # @param topic_id [String] topic to which we want to publish a message
              def publish(topic_id)
                @topic_id = topic_id

                deny! unless visibility_filter.publish?(@topic_id)

                # Ensures the topic exists (raises a not found otherwise) and gives the form the
                # number of partitions so we can hint the valid target partition range
                @partitions_count = Models::ClusterInfo.partitions_count(topic_id)

                # Default (empty) form state so the view can render blank fields
                assign_publish_form_state

                render
              end

              # Publishes a brand new message with the user-provided content to the given topic
              #
              # Supports two payload formats:
              # - `json` - the payload is parsed as JSON (validated) and re-serialized to its
              #   canonical JSON form, mirroring the default JSON payload deserializer used when
              #   consuming. Invalid JSON re-renders the form with an error.
              # - `raw` - the payload is produced exactly as provided (raw string / binary data).
              #
              # @param topic_id [String] topic to which we want to publish a message
              # @note This action is intentionally **not** named `produce` because that name
              #   collides with a producing helper mixed into the controller execution wrapper in
              #   the test suite, which would shadow the action.
              def dispatch(topic_id)
                @topic_id = topic_id

                deny! unless visibility_filter.publish?(@topic_id)

                # Validates the topic exists (raises a not found otherwise) before we attempt to
                # produce anything to it. Also feeds the partition hint if we re-render the form.
                @partitions_count = Models::ClusterInfo.partitions_count(topic_id)

                assign_publish_form_state

                # An uploaded file (if any) takes precedence over the textarea. This lets users
                # publish arbitrary binary payloads they generated elsewhere without pasting them.
                raw_payload = uploaded_payload || @payload

                payload = serialize_payload(raw_payload, @payload_format)
                headers = parse_headers(@headers)

                # Collect every validation problem so the user sees them all at once. `nil` from
                # `serialize_payload` means invalid JSON; `nil` from `parse_headers` means a
                # malformed header line (we validate rather than silently drop it, since a typo
                # could otherwise omit a header the user believes they are sending). On any error we
                # re-render the form (it reads the typed values back from the params, preserving
                # what the user entered) instead of producing a broken message.
                @publish_errors = []
                @publish_errors << invalid_payload_error if payload.nil?
                @publish_errors << malformed_headers_error if headers.nil?

                return publish(topic_id) if @publish_errors.any?

                dispatch_message = { topic: topic_id, payload: payload }

                dispatch_message[:key] = @key unless @key.empty?

                # Assign the target partition only if it was explicitly requested, otherwise we
                # let the producer decide based on the key (if present) or round-robin
                dispatch_message[:partition] = @partition.to_i unless @partition.empty?

                dispatch_message[:headers] = headers unless headers.empty?

                delivery = ::Karafka::Web.producer.produce_sync(dispatch_message)

                # Land back on the topic we just published to so the user can see their message,
                # regardless of where they navigated from
                redirect(
                  "explorer/topics/#{topic_id}",
                  success: published(delivery)
                )
              end

              # Dispatches the message raw payload to the browser as a file
              #
              # @param topic_id [String]
              # @param partition_id [Integer]
              # @param offset [Integer] offset of the message we want to download
              def download(topic_id, partition_id, offset)
                message = Models::Message.find(topic_id, partition_id, offset)

                deny! unless visibility_filter.download?(message)

                file(
                  message.raw_payload,
                  "#{topic_id}_#{partition_id}_#{offset}_payload.msg"
                )
              end

              # Dispatches the message payload first deserialized and then serialized to JSON
              # It differs from the raw payload in cases where raw payload is compressed or binary
              # or contains data that the Web UI user should not see that was altered on the Web UI
              # with the visibility filter.
              #
              # @param topic_id [String]
              # @param partition_id [Integer]
              # @param offset [Integer] offset of the message we want to export
              def export(topic_id, partition_id, offset)
                Lib::PatternsDetector.new.call

                message = Models::Message.find(topic_id, partition_id, offset)

                # Check if exports are allowed
                deny! unless visibility_filter.export?(message)

                # Payload may deserialize correctly but still not be serializable back to JSON,
                # for example when it contains non-UTF-8 byte sequences. In such cases there is
                # no JSON representation that could be exported
                payload_json = Lib::SafeRunner.new { message.payload.to_json }.tap(&:call)

                not_found!(topic_id) unless payload_json.success?

                file(
                  payload_json.result,
                  "#{topic_id}_#{partition_id}_#{offset}_payload.json"
                )
              end

              private

              # @param message [Karafka::Messages::Message]
              # @param delivery [Rdkafka::Producer::DeliveryReport]
              # @return [String] flash message about message reproducing
              def republished(message, delivery)
                format_flash(
                  "Message with offset ? has been sent to ?#? and received offset ?",
                  message.offset,
                  delivery.topic,
                  delivery.partition,
                  delivery.offset
                )
              end

              # Reads the publish form fields from the request params into instance variables so
              # both the initial form render and a failed submission re-render use the same state.
              # On the initial `#publish` GET the params are absent, so everything defaults to
              # empty (with `raw` as the default payload format).
              #
              # @return [void]
              def assign_publish_form_state
                # We use `fetch` with defaults because these fields are optional and may be absent
                # from the params. `params.str`/`params[]` would raise a `KeyError` on missing keys.
                @payload = params.fetch(:payload, "").to_s
                @key = params.fetch(:key, "").to_s
                @partition = params.fetch(:partition, "").to_s
                @headers = params.fetch(:headers, "").to_s
                @payload_format = params.fetch(:payload_format, "json").to_s
                @payload_format = "json" unless %w[raw json].include?(@payload_format)
              end

              # Reads the raw bytes of the uploaded payload file, if one was provided
              #
              # Rack exposes an uploaded file as a hash with a `:tempfile` handle. When the file
              # field is left empty the param is either absent or a blank string, in which case we
              # return nil so the caller falls back to the textarea payload.
              #
              # @return [String, nil] uploaded file bytes or nil when no file was uploaded
              def uploaded_payload
                file = params.fetch(:payload_file, nil)

                return nil unless file.is_a?(Hash)

                tempfile = file[:tempfile]

                return nil unless tempfile

                tempfile.read
              end

              # Serializes the user-provided payload according to the requested format
              #
              # @param raw [String] payload as typed by the user
              # @param format [String] either `raw` or `json`
              # @return [String, nil] the payload bytes to produce, or nil when JSON was requested
              #   but the provided content is not valid JSON
              def serialize_payload(raw, format)
                return raw unless format == "json"

                # Re-serialize so the produced bytes are canonical JSON, matching what the default
                # JSON deserializer will read back
                ::JSON.generate(::JSON.parse(raw))
              rescue ::JSON::ParserError
                nil
              end

              # @param delivery [Rdkafka::Producer::DeliveryReport]
              # @return [String] flash message about the published message
              #
              # @note The delivery report does not always carry a valid offset (for example the very
              #   first produce to a freshly created topic returns `RD_KAFKA_OFFSET_INVALID`, even
              #   though the message is persisted). We only show the offset when it is a real one.
              def published(delivery)
                return published_with_offset(delivery) unless delivery.offset.negative?

                format_flash(
                  "Message has been published to ?#?",
                  delivery.topic,
                  delivery.partition
                )
              end

              # @param delivery [Rdkafka::Producer::DeliveryReport]
              # @return [String] flash message including the assigned offset
              def published_with_offset(delivery)
                format_flash(
                  "Message has been published to ?#? and received offset ?",
                  delivery.topic,
                  delivery.partition,
                  delivery.offset
                )
              end

              # @return [String] error shown when the payload cannot be parsed as JSON
              def invalid_payload_error
                "Provided payload is not valid JSON and could not be serialized."
              end

              # @return [String] error shown when a header line is not in the `key: value` format
              def malformed_headers_error
                "Each header must be on its own line in the `key: value` format."
              end

              # Parses and validates the user-provided headers textarea into a hash of headers
              #
              # Each non-blank line must be in the `key: value` format. The key is the part before
              # the first colon and everything after it is the value. Blank lines are ignored. A
              # malformed line (no colon, or an empty key) is treated as an error rather than being
              # silently dropped, so a typo can never quietly omit a header the user intended.
              #
              # @param raw [String] raw textarea content with one `key: value` per line
              # @return [Hash{String => String}, nil] parsed headers, nil if a line is malformed
              def parse_headers(raw)
                headers = {}

                raw.each_line do |line|
                  next if line.strip.empty?

                  key, value = line.split(":", 2)

                  return nil if value.nil?

                  key = key.strip

                  return nil if key.empty?

                  headers[key] = value.strip
                end

                headers
              end

              # @return [Object] visibility filter. Either default or user-based
              def visibility_filter
                ::Karafka::Web.config.ui.policies.messages
              end
            end
          end
        end
      end
    end
  end
end
