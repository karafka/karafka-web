# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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
              def show(topic_name)
                @topic = Models::Topic.find(topic_name)

                @configs = refine(@topic.configs)

                render
              end

              # Allows for editing of a particular configuration setting
              # To simplify things we do not allow for batch editing of multiple parameters
              def edit
                raise
              end

              # Tries to apply config change on a topic and either returns the error info or
              # redirects if changed
              def update
                raise
              end
            end
          end
        end
      end
    end
  end
end
