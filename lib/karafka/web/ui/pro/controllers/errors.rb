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
    module Ui
      module Pro
        module Controllers
          # Errors details controller
          class Errors < Ui::Controllers::Base
            # @param partition_id [Integer] id of the partition of errors we are interested in
            def index(partition_id)
              errors_topic = ::Karafka::Web.config.topics.errors
              @partition_id = partition_id
              @error_messages, last_page, @partitions_count = \
                Models::Message.page(
                  errors_topic,
                  @partition_id,
                  @params.current_page
                )

              @page_scope = Ui::Lib::PageScopes::PageBased.new(
                @params.current_page,
                !last_page
              )

              @watermark_offsets = Ui::Models::WatermarkOffsets.find(errors_topic, @partition_id)

              respond
            end

            # Shows given error details
            #
            # @param partition_id [Integer]
            # @param offset [Integer]
            def show(partition_id, offset)
              errors_topic = ::Karafka::Web.config.topics.errors
              @partition_id = partition_id
              @offset = offset
              @error_message = Models::Message.find(
                errors_topic,
                @partition_id,
                @offset
              )

              respond
            end
          end
        end
      end
    end
  end
end
