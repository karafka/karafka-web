# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Namespace for request related components
        module Requests
          # Internal representation of params with sane sanitization
          class Params
            # What ranges we support for charts
            # Anything else will be rejected
            ALLOWED_RANGES = %w[
              seconds
              minutes
              hours
              days
            ].freeze

            private_constant :ALLOWED_RANGES

            # @param request_params [Hash] raw hash with params
            def initialize(request_params)
              @request_params = request_params
            end

            # @return [Hash] current search or empty if no search query present
            def current_search
              return @current_search if @current_search

              search = @request_params['search']

              @current_search = search.is_a?(Hash) ? search : {}
            end

            # @return [String] sort query value
            def current_sort
              @current_sort ||= @request_params['sort'].to_s.downcase
            end

            # @return [Integer] current page for paginated views
            # @note It does basic sanitization
            def current_page
              @current_page ||= begin
                page = @request_params['page'].to_i

                page.positive? ? page : 1
              end
            end

            # @return [String] Range type for charts we want to fetch
            def current_range
              candidate = @request_params.fetch('range', 'seconds')
              candidate = ALLOWED_RANGES.first unless ALLOWED_RANGES.include?(candidate)
              candidate.to_sym
            end

            # @return [Integer] offset from which we want to start. `-1` indicates, that we want
            #   to show the first page discovered based on the high watermark offset. If no offset
            #   is provided, we go with the high offset first page approach
            def current_offset
              @current_offset ||= begin
                offset = @request_params.fetch('offset', -1).to_i
                offset < -1 ? -1 : offset
              end
            end

            # @return [Integer] currently selected partition or -1 if nothing provided
            def current_partition
              @current_partition ||= @request_params.fetch('partition', -1).to_i
            end
          end
        end
      end
    end
  end
end
