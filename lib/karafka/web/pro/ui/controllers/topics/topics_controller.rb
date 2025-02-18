# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Topics
            # The primary controller for topics listing and creation / removal
            class TopicsController < BaseController
              self.sortable_attributes = [].freeze

              # Displays list of topics we can work with
              def index
                @topics = Models::Topic.all.sort_by(&:topic_name)

                unless ::Karafka::Web.config.ui.visibility.internal_topics
                  @topics.delete_if { |topic| topic[:topic_name].start_with?('__') }
                end

                render
              end

              # Renders form for creating a new topic with basic details like number of partitions
              # and the replication factor
              def new
                raise
              end

              # Creates topic and redirects on success
              def create
                raise
              end
            end
          end
        end
      end
    end
  end
end
