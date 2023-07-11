# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        module Paginations
          module Paginators
            class Base
              class << self
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
