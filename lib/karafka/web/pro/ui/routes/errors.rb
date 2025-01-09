# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the errors related routes
          class Errors < Base
            route do |r|
              r.on 'errors' do
                controller = Controllers::ErrorsController.new(params)

                r.get Integer, Integer do |partition_id, offset|
                  if params.current_offset != -1
                    r.redirect root_path('errors', partition_id, params.current_offset)
                  else
                    controller.show(partition_id, offset)
                  end
                end

                r.get Integer do |partition_id|
                  controller.partition(partition_id)
                end

                r.get do
                  controller.index
                end
              end
            end
          end
        end
      end
    end
  end
end
