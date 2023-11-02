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

            def_delegators ::Karafka::Admin, :read_watermark_offsets, :cluster_info

            # Allows us to read messages from the topic
            #
            # @param name [String, Symbol] topic name
            # @param partition [Integer] partition
            # @param count [Integer] how many messages we want to get at most
            # @param start_offset [Integer, Time] offset from which we should start. If -1 is provided
            #   (default) we will start from the latest offset. If time is provided, the appropriate
            #   offset will be resolved. If negative beyond -1 is provided, we move backwards more.
            # @param settings [Hash] kafka extra settings (optional)
            #
            # @return [Array<Karafka::Messages::Message>] array with messages
            def read_topic(name, partition, count, start_offset = -1, settings = {})
              ::Karafka::Admin.read_topic(
                name,
                partition,
                count,
                start_offset,
                # Merge our Web UI specific settings
                config.merge(settings)
              )
            end

            private

            # @return [Hash] kafka config for Web UI interface.
            # @note It does **not** affect tracking or processing
            def config
              ::Karafka::Web.config.ui.kafka
            end
          end
        end
      end
    end
  end
end
