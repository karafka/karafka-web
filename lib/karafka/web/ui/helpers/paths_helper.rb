# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Helpers
        # Helper for web ui paths builders
        module PathsHelper
          # Generates a full path with the root path out of the provided arguments
          #
          # @param args [Array<String, Numeric>] arguments that will make the path
          # @return [String] path from the root
          #
          # @note This needs to be done that way with the `#root_path` because the web UI can be
          #   mounted in a sub-path and we need to make sure our all paths are relative to "our"
          #   root, not the root of the app in which it was mounted.
          def root_path(*args)
            "#{env.fetch('SCRIPT_NAME')}/#{args.join('/')}"
          end

          # Generates a full path to any asset with our web-ui version. We ship all assets with
          # the version in the url to prevent those assets from being used after update. After
          # each web-ui update, assets are going to be re-fetched as the url will change
          #
          # @param local_path [String] local path to the asset
          # @return [String] full path to the asst including correct root path
          def asset_path(local_path)
            root_path("assets/#{Karafka::Web::VERSION}/#{local_path}")
          end

          # Helps build explorer paths. We often link offsets to proper messages, etc so this
          # allows us to short-track this
          # @param topic_name [String, nil] name of the topic where we want to go within the
          #   explorer or nil if we want to just go to the explorer root
          # @param partition_id [Integer, nil] partition we want to display in the explorer or nil
          #   if we want to go to the topic root
          # @param offset [Integer, nil] offset of particular message or nil of we want to just go
          #   to the partition root
          # @return [String] path to the expected location
          def explorer_path(topic_name = nil, partition_id = nil, offset = nil)
            root_path(*['explorer', topic_name, partition_id, offset].compact)
          end
        end
      end
    end
  end
end
