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

          # Renders a keyword filtering form for the current listing.
          #
          # The form submits via GET to the current path, preserving every other query parameter
          # (most importantly the current sort) as hidden fields while resetting pagination, so
          # filtering always starts from the first page. When a keyword is active a "clear" link
          # is rendered next to the input.
          #
          # @param placeholder [String] input placeholder text
          # @return [String] html of the filtering form
          def filter_box(placeholder: "Filter...")
            hidden = preserved_filter_params.map do |key, value|
              "<input type=\"hidden\" name=\"#{h(key)}\" value=\"#{h(value)}\">"
            end.join

            clear = ""

            if filtering?
              clear = <<~HTML
                <a class="btn btn-ghost font-normal" href="#{current_path(filter: nil, page: nil)}">
                  Clear
                </a>
              HTML
            end

            <<~HTML
              <form method="get" action="#{h(request.path)}" class="filter-form flex gap-2 mb-3">
                #{hidden}
                <input
                  type="text"
                  name="filter"
                  value="#{h(params.current_filter)}"
                  placeholder="#{h(placeholder)}"
                  class="input input-bordered w-full max-w-md"
                  autocomplete="off"
                >
                <button type="submit" class="btn btn-primary font-normal">Filter</button>
                #{clear}
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

          private

          # @return [Hash] current request query parameters that we want to carry over when
          #   submitting the filtering form (everything except the filter keyword itself and the
          #   pagination, which we intentionally reset)
          def preserved_filter_params
            flatten_params("", request.params).reject do |key, _value|
              key == "filter" || key == "page"
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
