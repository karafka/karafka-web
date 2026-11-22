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
        # The one place every changing tool goes through before it acts. It keeps the MCP audit
        # topic out of reach of the MCP tools, so agents cannot alter or remove their own trail
        module Guard
          # Kinds of changes a changing tool can make to a topic
          OPERATIONS = %i[
            create_topic
            delete_topic
            repartition_topic
            produce
            delete_records
            alter_configs
            reset_offsets
          ].freeze

          class << self
            # @param tool [Tools::Base] changing tool instance with validated arguments
            # @raise [Errors::Mcp::PolicyDeniedError] when the tool would change the audit topic or
            #   does not name the topics it changes
            def check!(tool)
              operation = tool.class.operation

              unless OPERATIONS.include?(operation)
                raise Errors::Mcp::PolicyDeniedError, "Unknown change operation: #{operation}"
              end

              topics = tool.topics

              if !topics.is_a?(Array) || topics.empty?
                raise Errors::Mcp::PolicyDeniedError, "Changing tool does not name the topics it changes"
              end

              return unless topics.include?(::Karafka::Web.config.topics.mcp_audit.name)

              raise Errors::Mcp::PolicyDeniedError, "The MCP audit topic cannot be changed through MCP"
            end
          end
        end
      end
    end
  end
end
