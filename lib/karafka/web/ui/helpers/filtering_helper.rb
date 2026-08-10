# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Helpers
        # Helpers for rendering the keyword filtering (search) box on data tables. Companion to the
        # [[SortingHelper]]: sorting reorders a listing, filtering narrows it down.
        module FilteringHelper
          # @return [Boolean] true if a filtering keyword is currently active
          def filtering?
            !params.current_filter.empty?
          end

          # Renders a filtering form for the current listing.
          #
          # The form submits via GET to the current path, preserving every other query parameter
          # (most importantly the current sort) as hidden fields while resetting pagination, so
          # filtering always starts from the first page.
          #
          # It renders as a full-width search field with a "Search" submit button and a "Reset"
          # button (always present, but disabled when there is nothing to reset, so the layout does
          # not shift). When the controller exposes a `{ field => label }` map of filterable fields
          # (via `filter`), a field selector is fused into the left of the field so the user can
          # pick which attribute to filter on, and the placeholder follows the selected field.
          #
          # @param placeholder [String] input placeholder text
          # @return [String] html of the filtering form
          def filter_box(placeholder: "Filter...")
            hidden = preserved_filter_params.map do |key, value|
              "<input type=\"hidden\" name=\"#{h(key)}\" value=\"#{h(value)}\">"
            end.join

            # The reset button is always rendered so the layout (and the search button position)
            # stays put whether or not a filter is active. It is only disabled when there is
            # nothing to reset.
            reset =
              if filtering?
                %(<a class="btn btn-outline font-normal" href="#{h(filter_clear_path)}">Reset</a>)
              else
                %(<a class="btn btn-outline font-normal btn-disabled" aria-disabled="true">Reset</a>)
              end

            fields = Array(@filterable_fields)
            # A field selector only makes sense when there is more than one attribute to pick from;
            # single-attribute listings keep the plain keyword box.
            fielded = fields.size >= 2
            value_name = fielded ? "filter[value]" : "filter"

            if fielded
              selected = selected_filter_field(fields)
              # A field selector is present, so the placeholder should reflect the chosen field
              # rather than a fixed one. It follows the selected field on submit.
              placeholder = "Filter by #{filter_field_label(selected).downcase}..."
            end

            input = <<~HTML
              <input
                type="text"
                name="#{value_name}"
                value="#{h(params.current_filter)}"
                placeholder="#{h(placeholder)}"
                class="input w-full#{fielded ? " join-item" : " grow"}"
                autocomplete="off"
              >
            HTML

            control =
              if fielded
                %(<div class="join grow">#{filter_field_selector(fields, selected)}#{input}</div>)
              else
                input
              end

            <<~HTML
              <form method="get" action="#{h(request.path)}" class="filter-form flex gap-2 mb-3">
                #{hidden}
                #{control}
                <button type="submit" class="btn btn-primary font-normal">Search</button>
                #{reset}
              </form>
            HTML
          end

          # Non-destructively narrows a topics collection (routing or a consumer subscription) down
          # to the ones matching the current filtering keyword.
          #
          # A topic is kept when its own name matches or when any of the provided parent labels
          # (the consumer group and/or subscription group names shown as the section headers) match
          # the keyword. Matching a parent label keeps all of its topics, which is what a user
          # filtering by their consumer group name expects to see.
          #
          # This is used for views that render the live `Karafka::App.routes` (which we must never
          # mutate, unlike the per-request structures the [[Filter]] engine prunes in place) as well
          # as the per-process subscriptions view, so it always returns a new array and leaves the
          # source untouched.
          #
          # @param topics [Enumerable] topics of a subscription/consumer group
          # @param parent_labels [Array<String>] group names that, when matched, keep all the topics
          # @return [Array] all topics when no filtering is active, otherwise only the matching ones
          def visible_topics(topics, *parent_labels)
            return topics.to_a unless filtering?

            keyword = params.current_filter.downcase

            if parent_labels.any? { |label| label.to_s.downcase.include?(keyword) }
              return topics.to_a
            end

            topics.select { |topic| topic.name.to_s.downcase.include?(keyword) }
          end

          # Human friendly labels for the attributes we allow filtering on. Attributes not listed
          # here fall back to a humanized version of their name (see {#filter_field_label}), so
          # controllers only need to declare bare attribute names in `filterable_attributes`.
          FILTER_NAMES = {
            id: "Process ID",
            subscribed_topics: "Assigned topic",
            tags: "Tags",
            topic: "Topic",
            topic_name: "Topic",
            consumer: "Consumer",
            type: "Type",
            name: "Name",
            value: "Value",
            cron: "Cron",
            broker_name: "Broker"
          }.freeze

          private_constant :FILTER_NAMES

          private

          # @param attribute [String, Symbol] filterable attribute name
          # @return [String] human friendly label for the attribute
          def filter_field_label(attribute)
            FILTER_NAMES.fetch(attribute.to_sym) do
              attribute.to_s.tr("_", " ").split.map(&:capitalize).join(" ")
            end
          end

          # @param fields [Array<String, Symbol>] filterable attributes
          # @return [String] the currently selected filter field, defaulting to the first one when
          #   nothing (valid) is selected
          def selected_filter_field(fields)
            selected = params.current_filter_field

            fields.map(&:to_s).include?(selected) ? selected : fields.first.to_s
          end

          # Renders the field selector fused into the left of the filtering field.
          #
          # @param fields [Array<String, Symbol>] filterable attributes
          # @param selected [String] the currently selected field
          # @return [String] html of the select element
          def filter_field_selector(fields, selected)
            options = fields.map do |field|
              key = field.to_s
              chosen = (key == selected) ? " selected" : ""
              "<option value=\"#{h(key)}\"#{chosen}>#{h(filter_field_label(field))}</option>"
            end.join

            <<~HTML
              <select name="filter[field]" class="select join-item">
                #{options}
              </select>
            HTML
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

          # Escapes a value for safe inclusion in an HTML attribute
          # @param value [Object] value to escape
          # @return [String] escaped value
          def h(value)
            Rack::Utils.escape_html(value.to_s)
          end
        end
      end
    end
  end
end
