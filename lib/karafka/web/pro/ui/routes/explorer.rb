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
    module Pro
      module Ui
        module Routes
          # Manages the explorer related routes
          class Explorer < Base
            route do |r|
              r.on 'explorer' do
                r.get String, 'search' do |topic_id|
                  # Search has it's own controller but we want to have this in the explorer routing
                  # namespace because topic search is conceptually part of the explorer
                  controller = Controllers::SearchController.new(params)
                  controller.index(topic_id)
                end

                controller = Controllers::ExplorerController.new(params)

                r.get String, Integer, 'recent' do |topic_id, partition_id|
                  controller.recent(topic_id, partition_id)
                end

                r.get String, Integer, Integer, 'surrounding' do |topic_id, partition_id, offset|
                  controller.surrounding(topic_id, partition_id, offset)
                end

                r.get String, 'recent' do |topic_id|
                  controller.recent(topic_id, nil)
                end

                # Jumps to offset matching the expected time
                r.get String, Integer, Time do |topic_id, partition_id, time|
                  controller.closest(topic_id, partition_id, time)
                end

                r.get String, Integer, Integer do |topic_id, partition_id, offset|
                  # If when viewing given message we get an offset of different message, we should
                  # redirect there. This allows us to support pagination with the current engine
                  if params.current_offset != -1
                    r.redirect explorer_path(topic_id, partition_id, params.current_offset)
                  else
                    controller.show(topic_id, partition_id, offset)
                  end
                end

                r.get String, Integer do |topic_id, partition_id|
                  controller.partition(topic_id, partition_id)
                end

                r.get String do |topic_id|
                  controller.topic(topic_id)
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
