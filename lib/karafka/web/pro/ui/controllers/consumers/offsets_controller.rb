# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Consumers
            # Controller that allows us to see offset positions of a consumer and to align them
            # on running consumers
            #
            # @note Please note that the alignment of offset position works **only** for running
            #   consumers
            class OffsetsController < ConsumersController
              self.sortable_attributes = %w[
                id
                lag_hybrid
                committed_offset
                stored_offset
              ].freeze

              # @param process_id [String] id of the process we're interested in
              def index(process_id)
                subscriptions(process_id)

                render
              end

              # @param process_id [String] id of the process we're interested in
              def edit(process_id)
                subscriptions(process_id)

                render
              end

              # @param process_id [String] id of the process we're interested in
              def update(process_id)
                subscriptions(process_id)

                render
              end
            end
          end
        end
      end
    end
  end
end
