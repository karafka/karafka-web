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
          # Base for the tools that create or change topics, as the Web UI topics management
          # actions do
          class TopicChange < Base
            # Topics management must be enabled and internal topics visible, as in the Web UI
            def authorize!
              deny!("Topics management is disabled") unless Ui::Lib::Features.topics_management?

              return if ::Karafka::Web.config.ui.visibility.internal_topics
              return unless topic.start_with?("__")

              deny!("Internal topics are hidden in the Web UI")
            end

            # @return [Array<String>] the changed topic
            def topics
              [topic]
            end

            private

            # @param contract [Web::Contracts::Base] Web UI form contract
            # @param form [Hash] normalized Web UI form
            # @return [Hash] form when it passes the same checks as in the Web UI
            # @raise [Errors::Mcp::NoDataError] when the Web UI would refuse the form
            def validate(contract, form)
              errors = contract.new.call(form).errors

              return form if errors.empty?

              raise(
                Errors::Mcp::NoDataError,
                errors.map { |key, message| "#{key} #{message}" }.join(", ")
              )
            end

            # @return [Web::Ui::Models::Topic]
            # @raise [Errors::Mcp::NoDataError] when the topic does not exist
            def current
              @current ||= Web::Ui::Models::Topic.find(topic)
            rescue Errors::Ui::NotFoundError
              raise Errors::Mcp::NoDataError, "Topic #{topic} does not exist"
            end

            # @return [String]
            def topic
              @arguments.fetch(:topic)
            end
          end
        end
      end
    end
  end
end
