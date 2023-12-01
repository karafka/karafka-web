# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      # Namespace for controller related components in the Web UI app.
      module Controllers
        # Base controller from which all the controllers should inherit.
        class Base
          class << self
            # Attributes on which we can sort in a given controller
            attr_accessor :sortable_attributes
          end

          self.sortable_attributes = []

          # @param params [Karafka::Web::Ui::Controllers::Requests::Params] request parameters
          def initialize(params)
            @params = params
          end

          private

          # Builds the render data object with assigned attributes based on instance variables.
          #
          # @return [Responses::Render] data that should be used to render appropriate view
          def render
            attributes = {}

            scope = self.class.to_s.split('::').last.gsub(/(.)([A-Z])/, '\1_\2').downcase
            action = caller_locations(1, 1)[0].label

            instance_variables.each do |iv|
              next if iv.to_s.start_with?('@_')
              next if iv.to_s.start_with?('@params')

              attributes[iv.to_s.delete('@').to_sym] = instance_variable_get(iv)
            end

            Responses::Render.new(
              "#{scope}/#{action}",
              attributes
            )
          end

          # Builds a redirect data object with assigned flashes (if any)
          # @param path [String, Symbol] relative (without root path) path where we want to be
          #   redirected or `:back` to use referer back
          # @param flashes [Hash] hash where key is the flash type and value is the message
          # @return [Responses::Redirect] redirect result
          def redirect(path = :back, flashes = {})
            Responses::Redirect.new(path, flashes)
          end

          # Builds a file response object that will be used as a base to dispatch the file
          #
          # @param content [String] Payload we want to dispatch as a file
          # @param file_name [String] name under which the browser is suppose to save the file
          # @return [Responses::File] file response result
          def file(content, file_name)
            Responses::File.new(content, file_name)
          end

          # Builds a halt 403 response
          def deny
            Responses::Deny.new
          end

          # @param resources [Hash, Array, Lib::HashProxy] object for sorting
          # @return [Hash, Array, Lib::HashProxy] sorted results
          def refine(resources)
            Lib::Sorter.new(
              @params.sort,
              allowed_attributes: self.class.sortable_attributes
            ).call(resources)
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
