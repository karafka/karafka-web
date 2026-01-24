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
          # Matcher that checks if the current process ID matches the specified process ID
          # in the matchers hash. This is an optional matcher that only applies when
          # process_id is specified in the matchers.
          class ProcessId < Base
            # @return [Boolean] true if process_id criterion is specified in matchers
            def apply?
              !process_id.nil?
            end

            # @return [Boolean] true if process ID matches
            def matches?
              process_id == current_process_id
            end

            private

            # @return [String, nil] process ID from matchers hash
            def process_id
              message.payload.dig(:matchers, :process_id)
            end

            # @return [String] current process ID from sampler
            def current_process_id
              ::Karafka::Web.config.tracking.consumers.sampler.process_id
            end
          end
        end
      end
    end
  end
end
