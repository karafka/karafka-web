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
          # Module that aliases our features in the UI for controllers and views to simplify
          # features checks
          module Features
            class << self
              # @return [Boolean] is commanding turned on
              def commanding?
                ::Karafka::Web.config.commanding.active
              end

              # Ensures that commanding is on.
              # @raise [Karafka::Web::Errors::Ui::ForbiddenError] raised when commanding is off
              def commanding!
                return if commanding?

                forbidden!
              end

              # @return [Boolean] is topics managements turned on
              def topics_management?
                Karafka::Web.config.ui.topics.management.active
              end

              # @raise [Karafka::Web::Errors::Ui::ForbiddenError] raised when topic management is
              #   off
              def topics_management!
                return if topics_management?

                forbidden!
              end

              private

              # Raises the forbidden error
              def forbidden!
                raise Errors::Ui::ForbiddenError
              end
            end
          end
        end
      end
    end
  end
end
