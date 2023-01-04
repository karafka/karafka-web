# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Namespace for request related components
        module Requests
          # Internal representation of params with sane sanitization
          class Params
            # @param request_params [Hash] raw hash with params
            def initialize(request_params)
              @request_params = request_params
            end

            # @return [Integer] current page for paginated views
            # @note It does basic sanitization
            def current_page
              @current_page ||= begin
                page = @request_params['page'].to_i

                page.positive? ? page : 1
              end
            end
          end
        end
      end
    end
  end
end
