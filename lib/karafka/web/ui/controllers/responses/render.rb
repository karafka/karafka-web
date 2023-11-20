# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        # Response related components
        module Responses
          # Response render data object. It is used to transfer attributes assigned in controllers
          # into views
          # It acts as a simplification / transport layer for assigned attributes
          class Render
            attr_reader :path, :attributes

            # @param path [String] render path
            # @param attributes [Hash] attributes assigned in the controller
            def initialize(path, attributes)
              @path = path
              @attributes = attributes
            end
          end
        end
      end
    end
  end
end
