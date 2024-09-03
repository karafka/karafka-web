# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      # Namespace for controller related components in the Web UI app.
      module Controllers
        # Base controller from which all the controllers should inherit.
        class BaseController
          include Web::Ui::Lib::Paginations

          # Alias for easier referencing
          Models = Web::Ui::Models

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
          # @param attributes [Hash] attributes coming from the outside (in case of rebind)
          # @return [Responses::Render] data that should be used to render appropriate view
          def render(attributes: {})
            attributes = attributes.dup

            full_parts = self.class.to_s.split('::')
            separator = full_parts.index('Controllers')
            base = full_parts[(separator + 1)..]

            base.map!.with_index do |path_part, index|
              if index == (base.size - 1)
                path_part.gsub(/(.)([A-Z])/, '\1_\2').downcase.gsub('_controller', '')
              else
                path_part.gsub(/(.)([A-Z])/, '\1_\2').downcase
              end
            end

            scope = base.join('/')
            action = caller_locations(1, 1)[0].label.split('#').last

            attributes[:breadcrums_scope] = scope

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

          # Raises the deny error so we can render a deny block
          # We handle this that way so we can raise this from any place we want as long as within
          # the Roda flow and not only from controllers
          def deny!
            raise Errors::Ui::ForbiddenError
          end

          # @param resources [Hash, Array, Lib::HashProxy] object for sorting
          # @return [Hash, Array, Lib::HashProxy] sorted results
          def refine(resources)
            Lib::Sorter.new(
              @params.current_sort,
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

          # Raises the not found error
          #
          # @param resource_id [String] resource id that was not found
          # @raise [::Karafka::Web::Errors::Ui::NotFoundError]
          def not_found!(resource_id = '')
            raise(::Karafka::Web::Errors::Ui::NotFoundError, resource_id)
          end
        end
      end
    end
  end
end
