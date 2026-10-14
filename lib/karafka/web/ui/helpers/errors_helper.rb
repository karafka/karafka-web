# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Helpers
        # Helpers for rendering the errors views
        module ErrorsHelper
          # Badge styles for producer delivery statuses
          DELIVERY_STATUS_BADGES = {
            "persisted" => :badge_success,
            "possibly persisted" => :badge_warning,
            "not persisted" => :badge_error
          }.freeze

          private_constant :DELIVERY_STATUS_BADGES

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

          # @param status [String, nil] producer delivery status from the error details
          # @return [String, nil] badge html for a known status, nil otherwise
          def delivery_status_badge(status)
            badge = DELIVERY_STATUS_BADGES[status]

            badge ? send(badge, status) : nil
          end
        end
      end
    end
  end
end
