# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Helpers
        # Helper for web ui paths builders
        module PathsHelper
          # Method that can be used to have conditions in breadcrumbs, etc based on the action
          # we're in
          #
          # @param args [Array<Symbol>] action names we want to check
          # @return [Boolean] true if any matches the current action name
          def action?(*args)
            args.include?(@current_action_name)
          end

          # Helper method to flatten nested hashes and arrays
          # @param prefix [String] The prefix for nested keys, initially an empty string.
          # @param hash [Hash, Array] The nested hash or array to be flattened.
          # @param [Hash] result The hash to store the flattened key-value pairs.
          # @return [Hash] The flattened hash with keys in bracket notation suitable for URL
          #   encoding.
          def flatten_params(prefix, hash, result = {})
            if hash.is_a?(Hash)
              hash.each do |k, v|
                new_prefix = prefix.empty? ? k.to_s : "#{prefix}[#{k}]"
                flatten_params(new_prefix, v, result)
              end
            elsif hash.is_a?(Array)
              hash.each_with_index do |v, i|
                new_prefix = "#{prefix}[#{i}]"
                flatten_params(new_prefix, v, result)
              end
            else
              result[prefix] = hash.to_s
            end

            result
          end

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
          # @param args [Array<String>] sub-paths
          # @return [String] path to the expected location
          def explorer_path(*args)
            root_path(*['explorer', args.compact].flatten)
          end

          # Helps build topics paths
          #
          # @param args [Array<String>] path params for the topics scope
          # @return [String] topics scope path
          def topics_path(*args)
            root_path('topics', *args)
          end

          # Helps build consumers paths
          #
          # @param args [Array<String>] path params for consumers scope
          # @return [String] consumers scope path
          def consumers_path(*args)
            root_path('consumers', *args)
          end

          # Helps build per-consumer scope paths
          #
          # @param consumer_id [String] consumer process id
          # @param args [Array<String>] other path components
          # @return [String] per consumer specific path
          def consumer_path(consumer_id, *args)
            consumers_path(consumer_id, *args)
          end

          # Helps build scheduled messages paths.
          # Similar to the explorer helper one
          # @param topic_name [String]
          # @param partition_id [Integer, nil]
          # @param offset [Integer, nil]
          # @param action [String, nil]
          # @return [String] path to the expected location
          def scheduled_messages_explorer_path(
            topic_name = nil,
            partition_id = nil,
            offset = nil,
            action = nil
          )
            root_path(
              *['scheduled_messages', 'explorer', topic_name, partition_id, offset, action].compact
            )
          end
        end
      end
    end
  end
end
