# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        # Wrapper around Karafka Admin that alters its behaviours or injects Web UI interface
        # specific settings that optimize the responsiveness of the UI when operating on topics
        #
        # @note Not all commands need those optimizations, hence we alter only those that need
        #   that and we only expose those admin commands that are used in the Web-UI interface
        #   component.
        #
        # @note We expose here only admin methods used in the Web UI interface. Processing uses the
        #   `Karafka::Admin` with the defaults
        class Admin
          class << self
            extend Forwardable

            def_delegators ::Karafka::Admin, :cluster_info, :with_consumer

            # @param name_or_hash [String, Symbol, Hash] topic name or hash with topics and
            #   partitions
            # @param partition [Array<Integer>] partition (when name is given)
            # @return [Array<Integer, Integer>, Hash] low and high watermark offsets
            # @raise [Web::Errors::Ui::NotFoundError] when a topic name is not a valid Kafka name
            def read_watermark_offsets(name_or_hash, *partition)
              topic_names = name_or_hash.is_a?(Hash) ? name_or_hash.keys : [name_or_hash]
              topic_names.each { |topic_name| validate_topic_name!(topic_name) }

              ::Karafka::Admin.read_watermark_offsets(name_or_hash, *partition)
            end

            # @param topic_name [String] name of the topic
            # @return [Hash] topic details
            # @raise [Web::Errors::Ui::NotFoundError] when the name is not a valid Kafka name
            def topic_info(topic_name)
              validate_topic_name!(topic_name)

              ::Karafka::Admin.topic_info(topic_name)
            end

            # Allows us to read messages from the topic
            #
            # @param name [String, Symbol] topic name
            # @param partition [Integer] partition
            # @param count [Integer] how many messages we want to get at most
            # @param start_offset [Integer, Time] offset from which we should start. If -1 is
            #   provided (default) we will start from the latest offset. If time is provided, the
            #   offset will be resolved. If negative beyond -1 is provided, we move backwards more.
            # @param settings [Hash] kafka extra settings (optional)
            #
            # @return [Array<Karafka::Messages::Message>] array with messages
            # @raise [Web::Errors::Ui::NotFoundError] when the name is not a valid Kafka name
            def read_topic(name, partition, count, start_offset = -1, settings = {})
              validate_topic_name!(name)

              ::Karafka::Admin.read_topic(
                name,
                partition,
                count,
                start_offset,
                # Inject our Web UI specific settings as defaults, letting anything the caller
                # passes explicitly win over them
                Config::DefaultsInjector.call(settings.dup)
              )
            end

            private

            # Rejects a topic name Kafka cannot have, as an unknown topic, without a cluster call.
            # Some of those names crash librdkafka (karafka-rdkafka 0.32.2 and older).
            #
            # @param topic_name [String, Symbol] topic name
            # @raise [Web::Errors::Ui::NotFoundError] when the name is not a valid Kafka name
            def validate_topic_name!(topic_name)
              return if Contracts::TopicName.new.call({ topic_name: topic_name.to_s }).success?

              raise(Web::Errors::Ui::NotFoundError, topic_name)
            end
          end
        end
      end
    end
  end
end
