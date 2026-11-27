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
          # Contracts of the tools arguments
          module Contracts
            # Base for the tools arguments contracts. It loads the tools error messages and lets
            # each contract declare the arguments it accepts
            class Base < Web::Contracts::Base
              class << self
                private

                # Loads the tools error messages and rejects arguments other than the given ones
                #
                # @param names [Array<Symbol>] names of the accepted arguments
                def arguments(*names)
                  configure do |config|
                    config.error_messages = YAML.safe_load_file(
                      File.join(Karafka::Web.gem_root, "config", "locales", "pro_errors.yml")
                    ).fetch("en").fetch("validations").fetch("mcp_tools")
                  end

                  virtual do |data|
                    next if (data.keys - names).empty?

                    [[%i[arguments], :unknown]]
                  end
                end

                # Accepts the given arguments and the `confirm` and `dry_run` arguments every
                # destructive tool takes
                #
                # @param names [Array<Symbol>] names of the tool own arguments
                def destructive_arguments(*names)
                  arguments(*names, :confirm, :dry_run)

                  optional(:confirm) { |val| [true, false].include?(val) }
                  optional(:dry_run) { |val| [true, false].include?(val) }
                end
              end
            end
          end
        end
      end
    end
  end
end
