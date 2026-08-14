# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Ui
        # Namespace for the Pro-only Web UI view helpers.
        module Helpers
          # Helpers for rendering the keyword filtering (search) box on data tables. Companion
          # to the [[SortingHelper]]: sorting reorders a listing, filtering narrows it down.
          module FilteringHelper
            # @return [Boolean] true if a filtering keyword is currently active. Filtering
            #   (search) is a Pro-only feature, so this is always false in OSS.
            def filtering?
              return false unless ::Karafka.pro?

              !params.current_filter.empty?
            end

            # Renders a filtering form for the current listing.
            #
            # The form submits via GET to the current path, preserving every other query parameter
            # (most importantly the current sort) as hidden fields while resetting pagination, so
            # filtering always starts from the first page.
            #
            # It renders as a full-width search field with a "Search" submit button and a "Reset"
            # button (always present, but disabled when there is nothing to reset, so the layout
            # does not shift). When the controller exposes a `{ field => label }` map of filterable
            # fields (via `filter`), a field selector is fused into the left of the field so the
            # user can pick which attribute to filter on.
            #
            # The placeholder is intentionally a single generic default across every listing: a
            # field selector always accompanies the input and already tells the user which
            # attribute is being filtered, so a per-view placeholder would be redundant (and would
            # look stale until the form is submitted, since it is server-rendered and does not
            # follow the select live).
            #
            # @param labels [Hash] per-view overrides for the field selector labels, e.g.
            #   `labels: { id: "Task ID" }`. Anything not overridden falls back to the shared
            #   {FILTER_NAMES} map (and then to a humanized attribute name).
            # @return [String] html of the filtering form
            def filter_box(labels: {})
              # Filtering (search) is a Pro-only feature, so we render nothing in OSS.
              return "" unless ::Karafka.pro?

              # A field is either a plain attribute name or a key-alias descriptor; the selector only
              # cares about its name. We render the field selector whenever the controller exposes
              # any filterable field, so every search looks consistent (even single-field listings
              # show a one-option select).
              fields = Array(@filterable_fields).map { |field| filter_field_name(field) }
              fielded = fields.any?

              partial(
                "shared/filter_box",
                locals: {
                  fields: fields,
                  fielded: fielded,
                  selected: fielded ? selected_filter_field(fields) : nil,
                  labels: labels,
                  value_name: fielded ? "filter[value]" : "filter",
                  keyword: params.current_filter,
                  hidden_params: preserved_filter_params,
                  active: filtering?,
                  clear_path: filter_clear_path
                }
              )
            end

            # Human friendly labels for the attributes we allow filtering on. Attributes not listed
            # here fall back to a humanized version of their name (see {#filter_field_label}), so
            # controllers only need to declare bare attribute names in `filterable_attributes`.
            FILTER_NAMES = {
              id: "Process ID",
              subscribed_topics: "Subscriptions",
              tags: "Tags",
              topic: "Topic",
              topic_name: "Topic",
              consumer_group: "Consumer group",
              subscription_group: "Subscription group",
              consumer: "Consumer",
              type: "Type",
              name: "Name",
              value: "Value",
              cron: "Cron",
              broker_name: "Broker"
            }.freeze

            private_constant :FILTER_NAMES

            private

            # @param field [String, Symbol, #name] a filterable field: a plain attribute name or a
            #   key-alias descriptor
            # @return [String] the field's name
            def filter_field_name(field)
              field.respond_to?(:path) ? field.name.to_s : field.to_s
            end

            # @param attribute [String, Symbol] filterable attribute name
            # @param overrides [Hash] per-view label overrides (keyed by attribute)
            # @return [String] human friendly label for the attribute: a per-view override if given,
            #   otherwise the shared {FILTER_NAMES} entry, otherwise a humanized attribute name
            def filter_field_label(attribute, overrides = {})
              key = attribute.to_sym

              overrides.transform_keys(&:to_sym).fetch(key) do
                FILTER_NAMES.fetch(key) do
                  attribute.to_s.tr("_", " ").split.map(&:capitalize).join(" ")
                end
              end
            end

            # @param fields [Array<String, Symbol>] filterable attributes
            # @return [String] the currently selected filter field, defaulting to the first one when
            #   nothing (valid) is selected
            def selected_filter_field(fields)
              selected = params.current_filter_field

              fields.map(&:to_s).include?(selected) ? selected : fields.first.to_s
            end

            # Builds the path used by the "clear" control: the current path with all filtering and
            # pagination parameters removed.
            #
            # @return [String] path without any filter/page query parameters
            def filter_clear_path
              query = URI.encode_www_form(preserved_filter_params)

              query.empty? ? request.path : "#{request.path}?#{query}"
            end

            # @return [Hash] current request query parameters that we want to carry over when
            #   submitting the filtering form (everything except the filtering parameters themselves
            #   and the pagination, which we intentionally reset)
            def preserved_filter_params
              flatten_params("", request.params).reject do |key, _value|
                key == "filter" || key.start_with?("filter[") || key == "page"
              end
            end
          end
        end
      end
    end
  end
end
