# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Helpers
        # Helpers for rendering the errors views
        module ErrorsHelper
          # Backtrace frames that come from gems or Ruby itself. Error reports strip the app root
          # and the gem home, so depending on `GEM_HOME` a gem frame starts with `gems/` or with
          # the gem directory (`karafka-2.5.0/`, or `karafka-a1b2c3d4e5f6/` for a git gem). Thread
          # backtraces keep absolute paths. JRuby core frames are Java classes.
          FRAMEWORK_FRAME = %r{
            (\A|/)gems/
            | \A[^/\s]+-\d+(\.\d+)*[^/\s]*/
            | \A[^/\s]+-\h{12}/
            | \A<internal:
            | /lib/ruby/
            | \Aorg/jruby/
            | \Auri:classloader:
            | \.java:\d
          }x

          private_constant :FRAMEWORK_FRAME

          # The errors topic can also receive foreign or malformed messages (for example one a
          # user published to it by mistake). Returns the deserialized error payload only when it
          # is one of our own error reports (identified by the `schema_version` all of them carry);
          # otherwise `nil`, so the views can fall back to a placeholder instead of raising and
          # 500-ing the whole page.
          #
          # @param message [::Karafka::Web::Ui::Models::Message, Array] an error message or a
          #   compacted-offset marker (an array)
          # @return [Hash, false] the error payload when it is one of our reports, otherwise `false`
          def displayable_error(message)
            return false if message.is_a?(Array)

            payload = message.payload

            return false unless payload.is_a?(Hash) && payload[:schema_version]

            payload
          # A foreign payload can fail to deserialize (invalid JSON, or a corrupt zlib body); those
          # should not take the whole page down. Anything else is a real bug, so let it raise.
          rescue JSON::ParserError, Zlib::Error
            false
          end

          # @param status [Integer] librdkafka message persistence status
          # @return [String] human readable status
          def delivery_status_name(status)
            case status
            when ::Rdkafka::Bindings::RD_KAFKA_MSG_STATUS_PERSISTED
              "persisted"
            when ::Rdkafka::Bindings::RD_KAFKA_MSG_STATUS_POSSIBLY_PERSISTED
              "possibly persisted"
            when ::Rdkafka::Bindings::RD_KAFKA_MSG_STATUS_NOT_PERSISTED
              "not persisted"
            else
              status.to_s
            end
          end

          # @param frame [String] one backtrace line
          # @return [String] css class that mutes gem and Ruby frames and marks application ones
          def backtrace_frame_class(frame)
            frame.match?(FRAMEWORK_FRAME) ? "text-base-content/60" : "font-bold"
          end
        end
      end
    end
  end
end
