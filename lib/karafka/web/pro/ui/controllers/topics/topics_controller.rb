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

              after(:create, :delete) { cache.clear }

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
                features.topics_management!

                render
              end

              # Creates topic and redirects on success
              # @note Upon creation we do not redirect to the topic config page because it may take
              #   a topic a moment to be fully available in the cluster. We "buy" ourselves this
              #   time by redirecting user back to the topics list
              def create
                features.topics_management!

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

              # Renders a confirmation page for topic removal since it is a sensitive operation
              #
              # @param topic_name [String]
              def edit(topic_name)
                features.topics_management!

                @topic = Models::Topic.find(topic_name)
                @topic_name = topic_name

                render
              end

              # Deletes the requested topic
              #
              # @param topic_name [String] name of the topic we want to remove
              def delete(topic_name)
                features.topics_management!

                edit(topic_name)

                Karafka::Admin.delete_topic(topic_name)

                redirect(
                  'topics',
                  success: format_flash(
                    'Topic ? successfully deleted',
                    topic_name
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
