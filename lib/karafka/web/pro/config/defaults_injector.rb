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
      # Namespace for Pro configuration components
      module Config
        # Pro overlay for the Web UI kafka settings injector.
        #
        # It is prepended onto `Karafka::Web::Config::DefaultsInjector`'s singleton class when Pro
        # is loaded, and layers Pro-specific Web UI kafka settings on top of the OSS ones by
        # calling `super` (the OSS defaults) and merging its own on top. This mirrors how
        # `Karafka::Pro::Setup::DefaultsInjector` extends `Karafka::Setup::DefaultsInjector`.
        module DefaultsInjector
          # Pro-specific Web UI kafka settings layered on top of the OSS defaults.
          #
          # Empty for now: Pro does not tune the Web UI admin kafka settings differently from OSS
          # yet. This is the extension point where such settings would go, so wiring the overlay
          # now keeps the layering in place for when they are needed.
          KAFKA_DEFAULTS = {}.freeze

          # @return [Hash] OSS Web UI kafka settings merged with the Pro-specific ones. The Pro
          #   values win over the OSS ones for any shared key; per-call settings still win over
          #   both, since the injector only fills in keys the caller did not set.
          def defaults
            super.merge(KAFKA_DEFAULTS)
          end
        end
      end
    end
  end
end
