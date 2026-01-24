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
          module Branding
            # Contracts for checking branding related setup
            module Contracts
              # Makes sure, all the expected UI branding config is defined as it should be
              class Config < ::Karafka::Contracts::Base
                configure do |config|
                  config.error_messages = YAML.safe_load_file(
                    File.join(Karafka::Web.gem_root, 'config', 'locales', 'pro_errors.yml')
                  ).fetch('en').fetch('validations').fetch('config')
                end

                nested(:ui) do
                  nested(:branding) do
                    required(:type) do |val|
                      # Type of branding style wrapping needs to align with what we support
                      # in other places
                      ::Karafka::Web::Ui::Helpers::TailwindHelper::TYPES.include?(val)
                    end

                    required(:label) do |val|
                      val == false || (val.is_a?(String) && val.size.positive?)
                    end

                    required(:notice) do |val|
                      val == false || (val.is_a?(String) && val.size.positive?)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
