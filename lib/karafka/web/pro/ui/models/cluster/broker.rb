# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Ui
        # Namespace for models used only by the Pro Web UI
        module Models
          # Namespace for Pro models that represent what the Kafka cluster itself reports
          module Cluster
            # Represents a single broker data within the cluster
            class Broker < Web::Ui::Lib::HashProxy
              class << self
                # @return [Array<Broker>] all brokers in the cluster
                def all
                  Web::Ui::Models::Cluster::Info.fetch.brokers.map do |broker|
                    new(broker)
                  end
                end

                # Finds requested broker
                #
                # @param broker_id [String, Integer]
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
  end
end
