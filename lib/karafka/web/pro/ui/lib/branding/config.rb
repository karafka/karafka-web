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
          module Branding
            # Extra configuration for pro UI branding feature
            class Config
              extend ::Karafka::Core::Configurable

              # Type of styling aligned with Daisy. info, error, warning, success, primary
              setting :type, default: :info

              # String label with env name. Will be displayed below the logo
              setting :label, default: false

              # Additional wide alert notice to highlight extra details. Nothing if false
              setting :notice, default: false

              configure
            end
          end
        end
      end
    end
  end
end
