# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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
                  controller = build(Controllers::Explorer::SearchController)
                  controller.index(topic_id)
                end

                r.on 'messages' do
                  controller = build(Controllers::Explorer::MessagesController)

                  r.get(
                    String, :partition_id, Integer, 'forward'
                  ) do |topic_id, partition_id, offset|
                    controller.forward(topic_id, partition_id, offset)
                  end

                  r.post(
                    String, :partition_id, Integer, 'republish'
                  ) do |topic_id, partition_id, offset|
                    controller.republish(topic_id, partition_id, offset)
                  end

                  r.get(
                    String, :partition_id, Integer, 'download'
                  ) do |topic_id, partition_id, offset|
                    controller.download(topic_id, partition_id, offset)
                  end

                  r.get(
                    String, :partition_id, Integer, 'export'
                  ) do |topic_id, partition_id, offset|
                    controller.export(topic_id, partition_id, offset)
                  end
                end

                r.on 'topics' do
                  controller = build(Controllers::Explorer::ExplorerController)

                  r.get String, :partition_id, 'recent' do |topic_id, partition_id|
                    controller.recent(topic_id, partition_id)
                  end

                  r.get(
                    String, :partition_id, Integer, 'surrounding'
                  ) do |topic_id, partition_id, offset|
                    controller.surrounding(topic_id, partition_id, offset)
                  end

                  r.get String, 'recent' do |topic_id|
                    controller.recent(topic_id, nil)
                  end

                  # Jumps to offset matching the expected time
                  r.get String, :partition_id, 'closest', Time do |topic_id, partition_id, time|
                    controller.closest(topic_id, partition_id, time)
                  end

                  # Jumps to the offset matching the expected timestamp
                  r.get(
                    String, :partition_id, 'closest', Integer
                  ) do |topic_id, partition_id, timestamp|
                    # To simplify we just convert timestamp to time with ms precision
                    time = Time.at(timestamp / 1_000.0)
                    controller.closest(topic_id, partition_id, time)
                  end

                  r.get String, :partition_id, Integer do |topic_id, partition_id, offset|
                    # If when viewing given message we get an offset of different message, we should
                    # redirect there. This allows us to support pagination with the current engine
                    if params.current_offset != -1
                      r.redirect explorer_topics_path(
                        topic_id,
                        partition_id,
                        params.current_offset
                      )
                    else
                      controller.show(topic_id, partition_id, offset)
                    end
                  end

                  r.get String, :partition_id do |topic_id, partition_id|
                    controller.partition(topic_id, partition_id)
                  end

                  r.get String do |topic_id|
                    controller.topic(topic_id)
                  end

                  r.get do
                    controller.index
                  end
                end

                r.get do
                  r.redirect root_path('explorer/topics')
                end
              end
            end
          end
        end
      end
    end
  end
end
