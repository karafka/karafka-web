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
        module Lib
          # Turns the consumer-commanding forms (partition seek, partition and topic pause/resume)
          # into commanding requests.
          module Commands
            # Turns raw request params of the commanding forms into typed hashes. Each form has a
            # dedicated method so the controllers stay declarative about what they submit.
            #
            # Numeric fields are kept as raw strings (via `fetch`, so a missing key does not raise)
            # and their format is validated by the contracts, so a malformed or absent value fails
            # validation instead of being silently coerced (`"abc".to_i => 0`) or 500-ing.
            module Normalizer
              class << self
                # @param params [Karafka::Web::Ui::Controllers::Requests::Params] request params
                # @return [Hash] typed seek (offset adjustment) form data
                def seek(params)
                  {
                    offset: params.fetch(:offset, "").to_s,
                    prevent_overtaking: truthy?(params.fetch(:prevent_overtaking, "")),
                    force_resume: truthy?(params.fetch(:force_resume, ""))
                  }
                end

                # @param params [Karafka::Web::Ui::Controllers::Requests::Params] request params
                # @return [Hash] typed pause form data. Duration stays in seconds (as entered);
                #   the conversion to milliseconds happens in {Transform} when the payload is built.
                def pause(params)
                  {
                    duration: params.fetch(:duration, "").to_s,
                    prevent_override: truthy?(params.fetch(:prevent_override, ""))
                  }
                end

                # @param params [Karafka::Web::Ui::Controllers::Requests::Params] request params
                # @return [Hash] typed resume form data
                def resume(params)
                  {
                    reset_attempts: truthy?(params.fetch(:reset_attempts, ""))
                  }
                end

                private

                # @param value [Object] raw checkbox value
                # @return [Boolean] whether the value represents a checked checkbox
                def truthy?(value)
                  %w[on yes true].include?(value.to_s)
                end
              end
            end
          end
        end
      end
    end
  end
end
