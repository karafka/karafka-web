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
          # filtering always starts from the first page.
          #
          # It renders as a compact, right-aligned search field: a small input with an inline
          # magnifying-glass icon and (when a keyword is active) a small clear (x) control. There is
          # no submit button, the form is submitted by pressing Enter.
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
                <a
                  href="#{current_path(filter: nil, page: nil)}"
                  class="opacity-50 hover:opacity-100 cursor-pointer"
                  title="Clear filter"
                  aria-label="Clear filter"
                >#{icon(:x_mark, size: 4)}</a>
              HTML
            end

            <<~HTML
              <form method="get" action="#{h(request.path)}" class="filter-form flex justify-end mb-3">
                #{hidden}
                <label class="input input-sm flex items-center gap-2 w-full max-w-xs">
                  <span class="opacity-50">#{icon(:magnifying_glass, size: 4)}</span>
                  <input
                    type="text"
                    name="filter"
                    value="#{h(params.current_filter)}"
                    placeholder="#{h(placeholder)}"
                    class="grow"
                    autocomplete="off"
                  >
                  #{clear}
                </label>
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
