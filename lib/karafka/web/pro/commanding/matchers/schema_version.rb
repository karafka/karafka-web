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
      module Commanding
        module Matchers
          # Matcher that checks if the message schema version matches the current dispatcher
          # schema version. This ensures compatibility between command producers and consumers.
          # This is a required matcher that always applies.
          class SchemaVersion < Base
            # Required matcher - check second (after message type)
            self.priority = 1

            # @return [Boolean] true if schema version matches
            def matches?
              message.payload[:schema_version] == Dispatcher::SCHEMA_VERSION
            end
          end
        end
      end
    end
  end
end
