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
      module Mcp
        module Tools
          # Web UI setup checks and versions of the components, as on the Web UI Status page
          class Status < Base
            tool(
              "karafka_status",
              <<~TEXT.tr("\n", " ").strip,
                Checks of the Karafka Web UI setup, as on the Web UI Status page: whether the Web
                UI is enabled, the Kafka connection, its topics, partitions and replication, the
                initial consumers state and metrics, consumers reports, schemas and materializing
                lag, routing and commands topics, Pro subscription and producer. Each check has a
                status (success, info, warning, failure, or halted when a check it depends on
                failed) and details. Also returns the versions of the Karafka components. Use it
                first when other tools return no data.
              TEXT
              contract: Contracts::NoArguments.new
            )

            private

            # @return [Hash] status checks and components versions
            def fetch
              ::Karafka::Web.config.ui.cache.clear

              status = Web::Ui::Models::Status.new
              sampler = Web::Tracking::Sampler.new

              checks = Web::Ui::Models::Status::CHECKS.keys.to_h do |name|
                step = status.public_send(name)

                [name, { status: step.status, details: step.details }]
              end

              {
                checks: checks,
                components: {
                  ruby: sampler.ruby_version,
                  karafka: sampler.karafka_version,
                  karafka_web: sampler.karafka_web_version,
                  karafka_core: sampler.karafka_core_version,
                  rdkafka: sampler.rdkafka_version,
                  librdkafka: sampler.librdkafka_version,
                  waterdrop: sampler.waterdrop_version
                }
              }
            end
          end
        end
      end
    end
  end
end
