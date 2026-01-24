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
          module Policies
            # Extra configuration for pro UI
            class Config
              extend ::Karafka::Core::Configurable

              # Policies controller related to messages operations and visibility
              setting :messages, default: Policies::Messages.new

              # Policies controller related to all requests. It is a general one that is not
              # granular but can be used to block completely certain pieces of the UI from
              # accessing like explorer or any other as operates on the raw env level
              setting :requests, default: Policies::Requests.new

              configure
            end
          end
        end
      end
    end
  end
end
