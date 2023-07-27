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

          private

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

          # Initializes the expected pagination engine and assigns expected arguments
          # @param args Any arguments accepted by the selected pagination engine
          def paginate(*args)
            engine = case args.count
                     when 2
                       Ui::Lib::Paginations::PageBased
                     when 3
                      Ui::Lib::Paginations::WatermarkOffsetsBased
                     when 4
                       Ui::Lib::Paginations::OffsetBased
                     else
                       raise ::Karafka::Errors::UnsupportedCaseError, args.count
                     end

            @pagination = engine.new(*args)
          end
        end
      end
    end
  end
end
