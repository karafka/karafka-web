# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Errors displaying controller
        # It supports only scenarios with a single partition for errors
        # If you have high load of errors, consider going Pro
        class Errors < Base
          # Lists first page of the errors
          def index
            @previous_page, @error_messages, @next_page, = Models::Message.page(
              errors_topic,
              0,
              @params.current_page
            )

            @watermark_offsets = Ui::Models::WatermarkOffsets.find(errors_topic, 0)

            respond
          end

          # @param offset [Integer] given error message offset
          def show(offset)
            @error_message = Models::Message.find(
              errors_topic,
              0,
              offset
            )

            respond
          end

          private

          # @return [String] errors topic
          def errors_topic
            ::Karafka::Web.config.topics.errors
          end
        end
      end
    end
  end
end
