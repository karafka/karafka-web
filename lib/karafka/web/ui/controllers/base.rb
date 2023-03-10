# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      # Namespace for controller related components in the Web UI app.
      module Controllers
        # Base controller from which all the controllers should inherit.
        class Base
          # @param params [Karafka::Web::Ui::Controllers::Requests::Params] request parameters
          def initialize(params)
            @params = params
          end

          # Builds the respond data object with assigned attributes based on instance variables.
          #
          # @return [Responses::Data] data that should be used to render appropriate view
          def respond
            attributes = {}

            scope = self.class.to_s.split('::').last.gsub(/(.)([A-Z])/, '\1_\2').downcase
            action = caller_locations(1, 1)[0].label

            instance_variables.each do |iv|
              next if iv.to_s.start_with?('@_')
              next if iv.to_s.start_with?('@params')

              attributes[iv.to_s.delete('@').to_sym] = instance_variable_get(iv)
            end

            Responses::Data.new(
              "#{scope}/#{action}",
              attributes
            )
          end
        end
      end
    end
  end
end
