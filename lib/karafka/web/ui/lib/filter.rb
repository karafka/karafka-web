# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        # Filtering engine for deep in-memory structures. It supports hashes, arrays and hash
        # proxies. It is a companion to the [[Sorter]] and follows the same wiring
        # (a per-controller allow-list plus an in-place `call`), but instead of reordering a
        # structure it removes the elements that do not match a keyword query.
        #
        # Matching is a case-insensitive substring check performed against the allowed attributes
        # of each element (via `public_send` or hash lookup) and against hash keys (so structural
        # labels such as topic or consumer group names are searchable).
        #
        # It uses match-propagation: a container (array/hash) is kept when it matches directly or
        # when any of its descendants match. That way filtering a nested structure by a topic name
        # keeps that topic with all of its children while dropping the branches that have nothing
        # in common with the query.
        #
        # @note It handles filtering in place by mutating appropriate resources and sub-components,
        #   exactly like the [[Sorter]]. Because of that it must only be used on structures that
        #   are safe to mutate (per-request data), never on shared/live structures like the app
        #   routing.
        class Filter
          # Max depth for nested filtering. Matches the sorter so both engines agree on how deep
          # they are willing to dive into a structure.
          MAX_DEPTH = 8

          private_constant :MAX_DEPTH

          # @param filter_query [String] keyword based on which we filter or empty string when no
          #   filtering is needed
          # @param allowed_attributes [Array<String, #path>, Hash] attributes on which we allow to
          #   filter. Since we can filter on method invocations, this needs to be limited and
          #   provided on a per controller basis (same contract as the sorter). It can be an array
          #   of attribute names or a `{ attribute => label }` hash (in which case only the keys
          #   matter here). An entry may also be a key-alias descriptor (any object responding to
          #   `name`/`path`), which matches nested hash keys at a path instead of record attributes
          #   (used for tree-shaped data whose labels are keys, e.g. the health stats).
          # @param field [String, nil] when provided (and allowed), filtering is scoped to this
          #   single attribute (or key alias) instead of matching the query against every allowed
          #   attribute. Used by the field-selectable filter on flat record listings.
          def initialize(filter_query, allowed_attributes:, field: nil)
            @query = filter_query.to_s.downcase.strip

            allowed = allowed_attributes.is_a?(Hash) ? allowed_attributes.keys : allowed_attributes

            # A declared field is either a plain attribute (matched on records) or a key alias
            # (matched on nested hash keys at a path). Key aliases are duck-typed: they respond to
            # `path` (a `KeyField`), which nothing else in the allow-list does.
            @allowed = []
            @aliases = {}

            Array(allowed).each do |attribute|
              if attribute.respond_to?(:path)
                @aliases[attribute.name.to_s] = attribute.path
              else
                # Normalize to strings so symbol keys from controllers and the string field coming
                # from the request params compare cleanly
                @allowed << attribute.to_s
              end
            end

            field = field.to_s

            # When the selected field is a key alias, filtering prunes hash keys at its path instead
            # of matching record attributes
            if @aliases.key?(field)
              @alias_path = @aliases[field]
            else
              @alias_path = nil
              @field = @allowed.include?(field) ? field : nil
            end

            # Things we have already seen and filtered. Prevents crashing (and infinite loops) on
            # circular dependencies when the same resources are present in different parts of the
            # tree. We cache the match result so a second visit returns the same answer.
            @seen = {}
          end

          # Filters the structure in place and returns it.
          #
          # @param resource [Hash, Array, Lib::HashProxy] structure we want to filter
          # @return [Hash, Array, Lib::HashProxy] the same structure with non-matching elements
          #   removed
          def call(resource)
            # Skip if there is nothing to filter on
            return resource if @query.empty?
            # Skip if there are no criteria to match against. Just like the sorter ignores a
            # disallowed field, we do not want to prune anything with nothing to match on.
            return resource if @allowed.empty? && @aliases.empty?

            if @alias_path
              # Field scoped to a key alias: prune the hash keys at the alias path
              keep_by_key_alias!(resource, @alias_path)
            else
              keep?(resource, 0)
            end

            resource
          end

          private

          # Recursively decides whether a given resource should be kept, pruning its non-matching
          # children in place along the way.
          #
          # @param resource [Object] structure or leaf we are evaluating
          # @param current_depth [Integer] current depth from the root
          # @return [Boolean] true if the resource (or any of its descendants) matches the query
          def keep?(resource, current_depth)
            # Do not prune beyond the max depth. We report a match so we never delete data we
            # refused to look into.
            return true if current_depth > MAX_DEPTH

            object_id = resource.object_id
            # Break circular references by returning the (optimistic) cached answer
            return @seen[object_id] if @seen.key?(object_id)

            @seen[object_id] = true

            result =
              case resource
              when Hash
                keep_hash!(resource, current_depth)
              when Lib::HashProxy
                # A hash proxy represents a single record (a process, a topic, a job). We match on
                # its allowed attributes and treat it as a leaf, we do not dive into its internals.
                record_match?(resource)
              when Array
                keep_array!(resource, current_depth)
              when String
                record_match?(resource)
              when Enumerable
                # Custom collections (e.g. the `Jobs` model) can be pruned only when they support
                # in-place selection. Otherwise we treat them as an opaque leaf record.
                if resource.respond_to?(:select!)
                  keep_array!(resource, current_depth)
                else
                  record_match?(resource)
                end
              else
                record_match?(resource)
              end

            @seen[object_id] = result
            result
          end

          # Prunes a nested hash in place so only the branches whose key at the aliased position
          # matches the query survive (with match-propagation up the tree). `path` is the sequence
          # of keys to descend from the container before matching that hash's keys (empty matches
          # the container's own keys).
          #
          # Descent is lenient: a key absent on a node falls back to the node itself, so trees that
          # nest the same logical level differently (e.g. one endpoint wraps topics under `:topics`,
          # another keys them directly) resolve without normalizing the data.
          #
          # @param hash [Object] structure to prune (a no-op unless it is a Hash)
          # @param path [Array] keys to descend before matching keys
          # @return [Boolean] true if anything was kept
          # @note This method modifies the hash in place (mutates the caller).
          def keep_by_key_alias!(hash, path)
            return false unless hash.is_a?(Hash)

            kept_any = false

            hash.select! do |key, value|
              # At the target level (empty path) we match the key itself; otherwise we descend and
              # recurse, keeping the branch when its sub-tree keeps anything
              kept =
                if path.empty?
                  matches?(key)
                else
                  keep_by_key_alias!(alias_descend(value, path.first), path[1..])
                end

              kept_any ||= kept
              kept
            end

            kept_any
          end

          # Lenient descent used by the key aliases: dig into `value[key]` when it is present,
          # otherwise use the value itself.
          #
          # @param value [Object] node we descend from
          # @param key [Object] key we descend into
          # @return [Object] the descended value (or the original value when the key is absent)
          def alias_descend(value, key)
            return value[key] if value.is_a?(Hash) && value.key?(key)

            value
          end

          # Filters an array in place, keeping only the elements that match (directly or through a
          # descendant).
          #
          # @param array [Array] array we want to filter
          # @param current_depth [Integer] current depth from the root
          # @return [Boolean] true if any element was kept
          # @note This method modifies the array in place (mutates the caller).
          def keep_array!(array, current_depth)
            # We only prune arrays whose elements we can actually reason about (records or nested
            # containers). Arrays of bare, non-matchable scalars are left untouched so we never
            # empty a collection we have no criteria for. This mirrors the sorter only acting on
            # collections it knows how to compare.
            return false unless array.any? { |element| actionable?(element) }

            any_kept = false

            array.select! do |element|
              kept = keep?(element, current_depth + 1)
              any_kept ||= kept
              kept
            end

            any_kept
          end

          # Filters a hash in place.
          #
          # A hash can play two roles. When it is a record (a row such as `{ name: ..., active:
          # ... }`) we match it as a whole on its allowed attributes and never prune its entries.
          # When it is a structural container (a nested map such as `consumer_group => topics`) we
          # prune its entries: an entry is kept when its key matches the query (in which case the
          # whole value subtree is preserved) or when its value subtree contains a match.
          #
          # @param hash [Hash] hash we want to filter
          # @param current_depth [Integer] current depth from the root
          # @return [Boolean] true if the hash matches directly or keeps at least one entry
          # @note This method modifies the hash in place (mutates the caller).
          def keep_hash!(hash, current_depth)
            return record_match?(hash) unless structural_hash?(hash)

            any_kept = false

            hash.select! do |key, value|
              if matches?(key)
                # The key (a structural label such as a topic name) matches, so we keep the whole
                # branch untouched
                any_kept = true
                true
              elsif prunable?(value)
                kept = keep?(value, current_depth + 1)
                any_kept ||= kept
                kept
              else
                # Sibling values that are not prunable are metadata (counts, timestamps, sets of
                # scalars) that live next to the nested collections we prune (e.g. `partitions_count`
                # next to `partitions`, or `rebalance_ages` next to `topics`). We never delete them
                # so we do not corrupt the records we keep, but on their own they do not keep the
                # parent branch alive.
                true
              end
            end

            any_kept
          end

          # A hash is treated as a structural container (to be pruned) rather than a record (to be
          # matched as a whole) when it does not expose any allowed attribute as a key and at least
          # one of its values is itself a nested container.
          #
          # @param hash [Hash] hash we want to classify
          # @return [Boolean] true if the hash should be pruned entry by entry
          def structural_hash?(hash)
            return false if @allowed.any? { |attribute| hash.key?(attribute) || hash.key?(attribute.to_sym) }

            hash.any? { |_key, value| prunable?(value) }
          end

          # Decides whether a value is something we should recurse into and prune. Plain hashes and
          # hash proxies (records) always are. Collections are only prunable when they hold
          # actionable elements, so a set/array of bare scalars (metadata) is left alone rather than
          # emptied.
          #
          # @param value [Object] value we want to classify
          # @return [Boolean] true if we should recurse into the value and prune it
          def prunable?(value)
            case value
            when Hash, Lib::HashProxy
              true
            when String
              false
            when Array
              value.any? { |element| actionable?(element) }
            when Enumerable
              value.respond_to?(:select!) && value.any? { |element| actionable?(element) }
            else
              false
            end
          end

          # @param element [Object] element we want to classify
          # @return [Boolean] true if the element is something we can prune on: a nested container
          #   or a record exposing at least one allowed attribute
          def actionable?(element)
            case element
            when Hash, Lib::HashProxy, Array, Enumerable
              true
            else
              matchable_record?(element)
            end
          end

          # @param element [Object] element we want to classify
          # @return [Boolean] true if the element responds to (or holds) at least one attribute we
          #   are matching on
          def matchable_record?(element)
            match_attributes.any? { |attribute| attribute_value(element, attribute) != NO_VALUE }
          end

          # Checks whether a record matches the query on any of the attributes we are matching on.
          #
          # @param element [Object] record we want to check
          # @return [Boolean] true if any matched attribute value includes the query
          def record_match?(element)
            match_attributes.any? do |attribute|
              value = attribute_value(element, attribute)

              value != NO_VALUE && matches?(value)
            end
          end

          # @return [Array<String>] the attributes to match on: just the selected field when
          #   filtering is scoped to one, otherwise all the allowed attributes
          def match_attributes
            @field ? [@field] : @allowed
          end

          # Extracts an allowed attribute value from a record, supporting both method invocations
          # and hash lookups (string and symbol keys).
          #
          # @param element [Object] record we want to read from
          # @param attribute [String] allowed attribute name
          # @return [Object] the attribute value or {NO_VALUE} when the record does not expose it
          def attribute_value(element, attribute)
            if element.respond_to?(attribute)
              element.public_send(attribute)
            elsif element.respond_to?(:key?)
              if element.key?(attribute)
                element[attribute]
              elsif element.key?(attribute.to_sym)
                element[attribute.to_sym]
              else
                NO_VALUE
              end
            else
              NO_VALUE
            end
          end

          # @param value [Object] value we want to match against the query
          # @return [Boolean] true if the (stringified) value includes the query (case-insensitive).
          #   Multi-valued attributes (arrays, e.g. a process's assigned topics or tags) match when
          #   any of their elements includes the query.
          def matches?(value)
            if value.is_a?(Array)
              value.any? { |element| element.to_s.downcase.include?(@query) }
            else
              value.to_s.downcase.include?(@query)
            end
          end

          # Sentinel used to distinguish "attribute is absent" from an attribute that legitimately
          # holds a `nil`/`false` value.
          NO_VALUE = Object.new.freeze

          private_constant :NO_VALUE
        end
      end
    end
  end
end
