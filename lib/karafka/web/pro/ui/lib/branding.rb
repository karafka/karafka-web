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
      module Ui
        module Lib
          # Namespace for UI branding related stuff
          # Branding allows users to set an extra label and notice per env so users won't be
          # confused by dev vs prod etc.
          module Branding
            class << self
              # Validates that the UI branding config is correct
              #
              # @param config [Karafka::Core::Configurable::Node] web config
              def post_setup(config)
                Branding::Contracts::Config.new.validate!(config.to_h)
              end
            end
          end
        end
      end
    end
  end
end
