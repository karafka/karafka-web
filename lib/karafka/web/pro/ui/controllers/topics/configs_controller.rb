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
        module Controllers
          module Topics
            # Controller responsible for management of topics configs
            class ConfigsController < BaseController
              self.sortable_attributes = %w[
                name
                value
                default?
                sensitive?
                read_only?
              ].freeze

              # Displays requested topic config details
              #
              # @param topic_name [String] topic we're interested in
              def index(topic_name)
                @topic = Models::Topic.find(topic_name)

                @configs = refine(@topic.configs)

                render
              end

              # Allows for editing of a particular configuration setting
              # To simplify things we do not allow for batch editing of multiple parameters
              # @param topic_name [String]
              # @param property_name [String]
              def edit(topic_name, property_name)
                features.topics_management!

                # This will load all the configs so we can validate that a requested config exists
                # and we can get its current value for the form
                index(topic_name)

                @property = @configs.find { |config| config.name == property_name }

                raise(Errors::Ui::NotFoundError) unless @property
                raise(Errors::Ui::ForbiddenError) if @property.read_only?

                render
              end

              # Tries to apply config change on a topic and either returns the error info or
              # redirects if changed
              # @param topic_name [String]
              # @param property_name [String]
              def update(topic_name, property_name)
                edit(topic_name, property_name)

                property_value = params[:property_value]

                begin
                  resource = Karafka::Admin::Configs::Resource.new(type: :topic, name: topic_name)
                  resource.set(property_name, property_value)
                  Karafka::Admin::Configs.alter(resource)
                rescue Rdkafka::RdkafkaError => e
                  @form_error = e
                end

                return edit(topic_name, property_name) if @form_error

                redirect(
                  "topics/#{topic_name}/config",
                  success: format_flash(
                    'Topic ? property ? successfully altered',
                    topic_name,
                    property_name
                  )
                )
              end
            end
          end
        end
      end
    end
  end
end
