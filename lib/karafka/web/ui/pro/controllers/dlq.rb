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
          # DLQ topics overview
          class Dlq < Ui::Controllers::Base
            # Lists DLQ topics
            def index
              topics = Karafka::App.consumer_groups.flat_map(&:topics).flat_map(&:to_a)

              dlq_topic_names = topics
                                .map { |source_topic| source_topic.dead_letter_queue.topic }
                                .uniq
                                .compact
                                .select(&:itself)

              @dlq_topics = Karafka::Admin
                            .cluster_info
                            .topics
                            .select { |topic| dlq_topic_names.include?(topic[:topic_name]) }
                            .sort_by { |topic| topic[:topic_name] }

              respond
            end
          end
        end
      end
    end
  end
end
