# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Ui
        module Routes
          # Manages the errors related routes
          class Errors < Base
            route do |r|
              r.on 'errors' do
                controller = build(Controllers::ErrorsController)

                r.get :partition_id, Integer do |partition_id, offset|
                  if params.current_offset == -1
                    controller.show(partition_id, offset)
                  else
                    r.redirect root_path('errors', partition_id, params.current_offset)
                  end
                end

                r.get :partition_id do |partition_id|
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
