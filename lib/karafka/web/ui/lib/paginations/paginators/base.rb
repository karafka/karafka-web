# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        module Paginations
          module Paginators
            # Base paginator
            class Base
              class << self
                # @return [Integer] number of elements per page
                def per_page
                  ::Karafka::Web.config.ui.per_page
                end
              end
            end
          end
        end
      end
    end
  end
end
