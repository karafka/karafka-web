# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

module Karafka
  module Web
    module Ui
      module Pro
        module Controllers
          # Topics management controller
          # Allows for exploration of settings and replication details
          class Topics < Ui::Controllers::Base
            include Ui::Lib::Paginations

            self.sortable_attributes = %w[
              name
              value
              default?
              read_only?
              synonym?
              sensitive?
              partition_id
              leader
              replica_count
              in_sync_replica_brokers
              count
              share
              diff
            ].freeze

            # Lists available topics in the cluster
            def index
              @topics = Models::Topic.all.sort_by(&:topic_name)

              unless ::Karafka::Web.config.ui.visibility.internal_topics
                @topics.delete_if { |topic| topic[:topic_name].start_with?('__') }
              end

              render
            end

            # Displays requested topic config details
            #
            # @param topic_name [String] topic we're interested in
            def config(topic_name)
              @topic = Models::Topic.find(topic_name)

              @configs = refine(@topic.configs)

              render
            end

            # Displays requested topic replication details
            #
            # @param topic_name [String] topic we're interested in
            def replication(topic_name)
              @topic = Models::Topic.find(topic_name)

              @partitions = refine(@topic[:partitions])

              render
            end

            # Displays the messages distribution across various partitions
            #
            # @param topic_name [String] topic we're interested in
            #
            # @note Because computing distribution is fairly expensive, we paginate this. While
            #   because of that results may not be exact, this allows us to support topics with
            #   many partitions.
            def distribution(topic_name)
              @topic = Models::Topic.find(topic_name)

              @active_partitions, materialized_page, @limited = Paginators::Partitions.call(
                @topic.partition_count, @params.current_page
              )

              @aggregated, distribution = @topic.distribution(@active_partitions)

              @distribution = refine(distribution)

              next_page = @active_partitions.last < @topic.partition_count - 1
              paginate(@params.current_page, next_page)

              render
            end
          end
        end
      end
    end
  end
end
