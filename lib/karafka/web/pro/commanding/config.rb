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
        # Extra configuration for pro commanding
        class Config
          extend ::Karafka::Core::Configurable

          # Management of processes is enabled by default
          setting :active, default: true

          # How long should we wait on command arrival before yielding. Having it too short will
          # cause unnecessary CPU cycles. Too long will make shutdown slower.
          setting :max_wait_time, default: 2_000

          # How long should we wait when an error occurs. Since this subscription is via the assign
          # API, we can just back-off and not care since we can always re-create the consumer on
          # issues. We always want to prevent a case where we would create new in a loop and
          # fail without backoff as this could overload the process.
          #
          # This should not happen often so waiting that long should not pose significant risks
          # and should not cause issues with the user-experience, since this is only commanding
          # connection
          setting :pause_timeout, default: 10_000

          # The underlying iterator requires specific settings, do not change this unless you know
          # what you area doing
          setting :kafka, default: {
            'enable.partition.eof': false,
            'auto.offset.reset': 'latest'
          }

          setting :listeners, default: [
            Handlers::Partitions::Listener.new,
            Handlers::Topics::Listener.new
          ]

          configure
        end
      end
    end
  end
end
