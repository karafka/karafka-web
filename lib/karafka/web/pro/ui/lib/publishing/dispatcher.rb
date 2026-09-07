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
          module Publishing
            # Produces the built message. The only side-effecting piece of the pipeline and the
            # single place that knows which producer user-initiated dispatches go through.
            class Dispatcher
              # @param message [Hash] message hash built by {Transform}
              def initialize(message)
                @message = message
              end

              # @return [Rdkafka::Producer::DeliveryReport] delivery report of the produced message
              def call
                producer.produce_sync(@message)
              end

              private

              # Resolves the producer used for user-initiated dispatches. We want the `acked`
              # (`acks: 1`) variant so the delivery report carries the assigned offset, rather than
              # the default fire-and-forget reporting producer. `Karafka::Web.producer` is normally
              # our wrapper (which provides `#acked`), but it is configurable and may be replaced
              # with a plain producer - in that case we use it as-is so publishing still works.
              #
              # @return [WaterDrop::Producer, WaterDrop::Producer::Variant] producer to publish with
              def producer
                web_producer = ::Karafka::Web.producer

                web_producer.respond_to?(:acked) ? web_producer.acked : web_producer
              end
            end
          end
        end
      end
    end
  end
end
