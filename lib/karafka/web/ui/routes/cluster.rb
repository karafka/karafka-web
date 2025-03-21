# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Routes
        # Manages the cluster related routes
        class Cluster < Base
          route do |r|
            r.on 'cluster' do
              controller = build(Controllers::ClusterController)

              r.get 'brokers' do
                controller.brokers
              end

              r.get 'replication' do
                controller.replication
              end

              r.redirect root_path('cluster/brokers')
            end
          end
        end
      end
    end
  end
end
