# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Selects cluster info and topics basic info
        class Cluster < Base
          # List cluster info data
          def index
            @cluster_info = Karafka::Admin.cluster_info

            @topics = @cluster_info
                      .topics
                      .reject { |topic| topic[:topic_name] == '__consumer_offsets' }
                      .sort_by { |topic| topic[:topic_name] }

            respond
          end
        end
      end
    end
  end
end
