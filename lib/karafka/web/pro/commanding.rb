# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      # Namespace for things related to consumers commanding (management)
      #
      # This feature allows for basic of consumers. They can be stopped, moved to quiet or traced
      # via the Web UI
      module Commanding
        class << self
          # Subscribes with the commanding manager when commanding is enabled
          #
          # @param config [Karafka::Core::Configurable::Node] web config
          def post_setup(config)
            # We do not use manager if commanding is not suppose to work at all
            return unless config.commanding.active

            Commanding::Contracts::Config.new.validate!(config.to_h)

            ::Karafka.monitor.subscribe(
              Commanding::Manager.instance
            )
          end
        end
      end
    end
  end
end
