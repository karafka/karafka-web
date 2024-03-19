# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Represents a single broker data within the cluster
        class Broker < Lib::HashProxy
          class << self
            # @return [Array<Broker>] all brokers in the cluster
            def all
              # We do not cache here because we want the most recent state of brokers possible
              ClusterInfo.fetch(cached: false).brokers.map do |broker|
                new(broker)
              end
            end

            # Finds requested broker
            #
            # @param broker_id [String, Integer] id of the broker
            # @return [Broker]
            # @raise [::Karafka::Web::Errors::Ui::NotFoundError]
            def find(broker_id)
              found = all.find { |broker| broker.id.to_s == broker_id }

              return found if found

              raise(::Karafka::Web::Errors::Ui::NotFoundError, broker_id)
            end
          end

          # @return [Integer]
          def id
            broker_id
          end

          # @return [String]
          def name
            broker_name
          end

          # @return [Integer]
          def port
            broker_port
          end

          # @return [String] full broker name for presentation
          def full_name
            "#{id} - #{name}:#{port}"
          end

          # @return [Array<Karafka::Admin::Configs::Config>] all broker configs
          def configs
            # We copy the array because the result one is frozen and we sort
            @configs ||= ::Karafka::Admin::Configs.describe(
              ::Karafka::Admin::Configs::Resource.new(
                type: :broker,
                name: id
              )
            ).first.configs.dup
          end
        end
      end
    end
  end
end
