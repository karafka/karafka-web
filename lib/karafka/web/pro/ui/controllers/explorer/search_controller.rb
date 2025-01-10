# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          module Explorer
            # Handles the search requests
            # We present this as a part of explorer scope but we use a separate controller not to
            # mix data exploring with searching.
            class SearchController < Web::Ui::Controllers::ClusterController
              # Runs the search if search parameters are provided
              # If no parameters provided, displays the search modal and info to provide search
              # data. If invalid search parameters provided, modal contains errors
              #
              # @param topic_id [String] topic we're interested in
              # @note In theory search can be used to detect pieces of information within messages.
              #   Since we allow for custom search strategies, this is not an issue because users
              #   that need to provide only granular search can do so.
              def index(topic_id)
                @topic_id = topic_id
                @partitions_count = Models::ClusterInfo.partitions_count(topic_id)
                # Select only matchers that should be available in the context of the current topic
                available_matchers = Web.config.ui.search.matchers
                @matchers = available_matchers.select { |match| match.active?(@topic_id) }
                @search_criteria = !@params.current_search.empty?
                @current_search = Lib::Search::Normalizer.call(@params.current_search)
                # Needed when rendering found messages rows. We should always filter the messages
                # details with the visibility filter
                @visibility_filter = ::Karafka::Web.config.ui.policies.messages
                @limits = ::Karafka::Web.config.ui.search.limits.sort

                # If there is search form filled, we validate it to make sure there are no errors
                @errors = if @search_criteria
                            Lib::Search::Contracts::Form.new.call(@current_search).errors
                          else
                            {}
                          end

                # If all good we run the search
                if @search_criteria && @errors.empty?
                  found, @search_details = Lib::Search::Runner.new(
                    @topic_id,
                    @partitions_count,
                    @current_search
                  ).call

                  @messages, last_page = Paginators::Arrays.call(
                    found,
                    @params.current_page
                  )

                  paginate(@params.current_page, !last_page)
                end

                render
              end
            end
          end
        end
      end
    end
  end
end
