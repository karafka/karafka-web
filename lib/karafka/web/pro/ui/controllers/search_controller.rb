# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

module Karafka
  module Web
    module Pro
      module Ui
        # Namespace for Pro controllers
        module Controllers
          class SearchController < Web::Ui::Controllers::ClusterController
            def index(topic_id)
              @topic_id = topic_id
              @partitions_count = Models::ClusterInfo.partitions_count(topic_id)
              @search_criteria = !@params.current_search.empty?
              @current_search = Lib::Search::Normalizer.call(@params.current_search)
              @visibility_filter = ::Karafka::Web.config.ui.visibility.filter

              if @search_criteria
                @errors = Lib::Search::Contract.new.call(@current_search).errors
              else
                @errors = {}
              end

              # If all good run search
              if @search_criteria && @errors.empty?
                found, @search_details = Lib::Search::Runner.call(
                  @topic_id,
                  @partitions_count,
                  @current_search
                )

                @messages, last_page = Paginators::Arrays.call(
                  found,
                  @params.current_page
                )

                paginate(@params.current_page, !last_page)
              end

              render
            end

            def show(topic_id)
              render
            end
          end
        end
      end
    end
  end
end
