# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      # Namespace for helpers used by the Web UI
      module Helpers
        # Application-wide helpers: navigation, layout, icons, empty states and generic hash
        # utilities. More specific concerns live in dedicated helpers ([[SortingHelper]],
        # [[FormattingHelper]], [[BadgesHelper]], [[PartitionsHelper]]).
        module ApplicationHelper
          # Adds active class to the current location in the nav if needed
          # @param location [Hash]
          def nav_class(location)
            comparator, value = location.to_a.first

            local_location = request.path.gsub(env.fetch("SCRIPT_NAME"), "")
            local_location.public_send(:"#{comparator}?", value) ? "active" : ""
          end

          # Sets the particular page title
          #
          # @param title [String] page title
          # @return [String] title html
          def view_title(title)
            content_for(:title) { title }
          end

          # @param hash [Hash] we want to flatten
          # @param parent_key [String] key for recursion
          # @param result [Hash] result for recursion
          # @return [Hash]
          def flat_hash(hash, parent_key = nil, result = {})
            hash.each do |key, value|
              current_key = parent_key ? "#{parent_key}.#{key}" : key.to_s
              if value.is_a?(Hash)
                flat_hash(value, current_key, result)
              elsif value.is_a?(Array)
                value.each_with_index do |item, index|
                  flat_hash({ index => item }, current_key, result)
                end
              else
                result[current_key] = value
              end
            end

            result
          end

          # Renders the svg icon out of our icon set
          # @param name [String, Symbol] name of the icon
          # @param size [Integer, nil] optional size override (defaults to the icon's own size)
          # @return [String] svg icon
          def icon(name, size: nil)
            render "shared/icons/_#{name}", locals: { size: size }
          end

          # Renders the standardized "nothing here" empty state (icon + message, optionally with
          # a description and a call-to-action button). The description can also be given as a
          # block, in which case it may contain arbitrary markup (e.g. a checklist).
          #
          # @param message [String] primary message describing what's empty
          # @param icon [String, Symbol] one of: inbox, document, search, folder, key
          # @param description [String, nil] optional secondary, smaller explanatory text
          # @param action [String, nil] optional call-to-action button label
          # @param action_path [String, nil] path the call-to-action button should link to
          # @param card [Boolean, nil] whether to wrap the state in a bordered card (default true)
          # @param block [Proc] optional block producing the description markup
          # @return [String] empty state html
          def empty_state(
            message,
            icon: "inbox",
            description: nil,
            action: nil,
            action_path: nil,
            card: nil,
            &block
          )
            description = capture_erb(&block) if block

            inject_erb partial(
              "shared/empty_state",
              locals: {
                message: message,
                icon_name: icon,
                description: description,
                action: action,
                action_path: action_path,
                card: card
              }
            )
          end

          # Merges two hashes deeply, combining nested hashes recursively.
          #
          # @param hash1 [Hash] The first hash to merge.
          # @param hash2 [Hash] The second hash to merge.
          # @return [Hash] A new hash that is the result of a deep merge of the two provided hashes.
          def deep_merge(hash1, hash2)
            merged_hash = hash1.dup

            hash2.each_pair do |k, v|
              tv = merged_hash[k]

              merged_hash[k] = if tv.is_a?(Hash) && v.is_a?(Hash)
                deep_merge(tv, v)
              else
                v
              end
            end

            merged_hash
          end
        end
      end
    end
  end
end
