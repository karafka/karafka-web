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
        module Models
          # Active processes with the Pro lookups
          module Processes
            class << self
              # @param state [State] current system state from which we can get processes metadata
              # @return [Array<Web::Ui::Models::Process>] processes that are running or recently
              #   shutdown, including those with incompatible schema
              def all(state)
                Web::Ui::Models::Processes.all(state)
              end

              # @param state [State] current system state from which we can get processes metadata
              # @return [Array<Web::Ui::Models::Process>] active processes with compatible schema
              def active(state)
                Web::Ui::Models::Processes.active(state)
              end

              # Looks for a given process based on its id
              #
              # @param state [State] state of the system based on which we will do the lookup
              # @param process_id [String] id of the process we are looking for
              # @return [Web::Ui::Models::Process] selected process
              # @raise [::Karafka::Web::Errors::Ui::NotFoundError] raised if process not found
              # @note Keep in mind, that this search is looking only within processes with a
              #   compatible schema, as it uses `#active` under the hood.
              def find(state, process_id)
                found_process = active(state).find { |process| process.id == process_id }
                found_process || raise(::Karafka::Web::Errors::Ui::NotFoundError, process_id)
              end

              # Maps the group member ids the active processes report to the process and the
              # subscription group (librdkafka client) holding each of them. Allows matching the
              # members the cluster reports with the processes running them. Members of applications
              # that do not report to the Web UI (e.g. non-Ruby ones) have no entry.
              #
              # @param state [State] current system state from which we can get processes metadata
              # @return [Hash{String => Hash}] `:process` and `:subscription_group` by member id
              def by_member_id(state)
                active(state).each_with_object({}) do |process, mapping|
                  process.consumer_groups.each do |consumer_group|
                    consumer_group.subscription_groups.each do |subscription_group|
                      # Reports of processes running versions that do not track it have no member id
                      member_id = subscription_group[:member_id].to_s

                      next if member_id.empty?

                      mapping[member_id] = { process: process, subscription_group: subscription_group }
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
