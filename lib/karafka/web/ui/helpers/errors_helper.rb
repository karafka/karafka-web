# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Helpers
        # Helpers for rendering the errors views
        module ErrorsHelper
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
          # Deserialization of a foreign payload can fail in many ways (invalid JSON, bad zlib
          # header, etc.); none of them should take the whole page down
          rescue
            false
          end
        end
      end
    end
  end
end
