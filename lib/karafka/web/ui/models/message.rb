# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # A proxy between `::Karafka::Messages::Message` and web UI
        # We work with the Karafka messages but use this model to wrap the work needed.
        class Message
          class << self
            # Looks for a message from a given topic partition
            #
            # @param topic_id [String]
            # @param partition_id [Integer]
            # @param offset [Integer]
            # @raise [::Karafka::Web::Errors::Ui::NotFoundError] when not found
            def find(topic_id, partition_id, offset)
              message = Karafka::Admin.read_topic(
                topic_id,
                partition_id,
                1,
                offset
              ).first

              return message if message

              raise(
                ::Karafka::Web::Errors::Ui::NotFoundError,
                [topic_id, partition_id, offset].join(', ')
              )
            end

            # Fetches requested page of Kafka messages.
            #
            # @param topic_id [String]
            # @param partition_id [Integer]
            # @param page [Integer]
            # @return [Array] We return both page data as well as all the details needed to build
            #   the pagination details.
            def page(topic_id, partition_id, page)
              # Establish the leading offset
              lead = Karafka::Admin.read_topic(topic_id, partition_id, 1).first

              partitions_count = fetch_partition_count(topic_id)

              # If there is not even one message, we need to early exit
              return [false, [], false, partitions_count] unless lead

              # We add plus one because we compute previous offset from which we want to start and
              # not previous page leading offset
              previous_offset = lead.offset - (per_page * page) + 1

              if previous_offset.negative?
                count = per_page + previous_offset
                previous_page = page < 2 ? false : page - 1
                next_page = false
                previous_offset = 0
              else
                previous_page = page < 2 ? false : page - 1
                next_page = page + 1
                count = per_page
              end

              [
                previous_page,
                read_topic(topic_id, partition_id, count, previous_offset).reverse,
                next_page,
                partitions_count
              ]
            end

            private

            # @param args [Object] anything required by the admin `#read_topic`
            # @return [Array<Karafka::Messages::Message>] topic partition messages
            def read_topic(*args)
              ::Karafka::Admin.read_topic(*args)
            end

            # @param topic_id [String] id of the topic
            # @return [Integer] number of partitions this topic has
            def fetch_partition_count(topic_id)
              ::Karafka::Admin
                .cluster_info
                .topics
                .find { |topic| topic[:topic_name] == topic_id }
                .fetch(:partition_count)
            end

            # @return [Integer] elements per page
            def per_page
              ::Karafka::Web.config.ui.per_page
            end
          end
        end
      end
    end
  end
end
