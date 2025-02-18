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
                only_with_management_active!

                render
              end

              # Creates topic and redirects on success
              # @note Upon creation we do not redirect to the topic config page because it may take
              #   a topic a moment to be fully available in the cluster. We "buy" ourselves this
              #   time by redirecting user back to the topics list
              def create
                only_with_management_active!

                begin
                  Karafka::Admin.create_topic(
                    params[:topic_name],
                    params.int(:partitions_count),
                    params.int(:replication_factor)
                  )
                rescue Rdkafka::RdkafkaError => e
                  @form_error = e
                end

                return new if @form_error

                redirect(
                  'topics',
                  success: format_flash(
                    'Topic ? successfully created',
                    params[:topic_name]
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
