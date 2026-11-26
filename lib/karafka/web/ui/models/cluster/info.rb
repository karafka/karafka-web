# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Namespace for models that represent what the Kafka cluster itself reports
        module Cluster
          # Wraps around the `Lib::Admin#cluster_info` with caching
          class Info
            class << self
              # Gets us all the cluster metadata info
              #
              # @return [Rdkafka::Metadata] cluster metadata info
              def fetch
                Karafka::Web.config.ui.cache.fetch(:cluster_info) do
                  Lib::Admin.cluster_info
                end
              end
            end
          end
        end
      end
    end
  end
end
