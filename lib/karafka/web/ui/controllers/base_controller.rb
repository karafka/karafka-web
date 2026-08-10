# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      # Namespace for controller related components in the Web UI app.
      module Controllers
        # Base controller from which all the controllers should inherit.
        class BaseController
          include Web::Ui::Lib::Paginations
          include Requests::Hookable

          attr_reader :params, :session

          # Alias for easier referencing
          Models = Web::Ui::Models

          class << self
            # Attributes on which we can sort in a given controller
            attr_accessor :sortable_attributes

            # Attributes on which we can filter in a given controller. Since we can filter on
            # method invocations, this needs to be limited and provided on a per controller basis
            # (same contract as `sortable_attributes`).
            attr_accessor :filterable_attributes
          end

          self.sortable_attributes = []
          self.filterable_attributes = []

          # Detect that the state of the cache has changed
          before do
            cache.clear_if_needed(
              session["cache_hash"],
              session["cache_timestamp"].to_i
            )
          end

          after do
            next unless cache.exist?

            session["cache_hash"] = cache.hash
            session["cache_timestamp"] = cache.timestamp.to_i
          end

          # @param params [Karafka::Web::Ui::Controllers::Requests::Params] request parameters
          # @param session [Request::Session] request session (Rails or other framework)
          def initialize(params, session)
            @params = params
            @session = session
          end

          # @return [Karafka::Web::Ui::Lib::Cache] per-process cache instance
          def cache
            Karafka::Web.config.ui.cache
          end

          private

          # Builds the render data object with assigned attributes based on instance variables.
          #
          # @param attributes [Hash] attributes coming from the outside (in case of rebind)
          # @return [Responses::Render] data that should be used to render appropriate view
          def render(attributes: {})
            attributes = attributes.dup

            full_parts = self.class.to_s.split("::")
            separator = full_parts.index("Controllers")
            base = full_parts[(separator + 1)..]

            base.map!.with_index do |path_part, index|
              if index == (base.size - 1)
                path_part.gsub(/(.)([A-Z])/, '\1_\2').downcase.gsub("_controller", "")
              else
                path_part.gsub(/(.)([A-Z])/, '\1_\2').downcase
              end
            end

            scope = base.join("/")
            action = caller_locations(1, 1)[0].label.split("#").last

            attributes[:breadcrums_scope] = scope

            @current_action_name = action.to_sym
            @current_controller_name = base.join("-")

            instance_variables.each do |iv|
              next if iv.to_s.start_with?("@_")
              next if iv.to_s.start_with?("@params")

              attributes[iv.to_s.delete("@").to_sym] = instance_variable_get(iv)
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

          # Wraps the provided arguments inside a message with a `<strong>` tag to simplify flash
          # messages building.
          #
          # @param message [String] message with `?` to be replaced.
          # @param args [Array<Object>] arguments to use to replace `?` with strong
          # @return [String] formatted string
          def format_flash(message, *args)
            args.each do |arg|
              message = message.sub("?", "<strong>#{arg}</strong>")
            end

            message
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
          def sort(resources)
            Lib::Sorter.new(
              @params.current_sort,
              allowed_attributes: self.class.sortable_attributes
            ).call(resources)
          end

          # Filters the provided resources in place based on the current filtering keyword and the
          # attributes allowed for filtering.
          #
          # @param resources [Hash, Array, Lib::HashProxy] object for filtering
          # @param fields [Array<Symbol>, nil] attributes to filter on, overriding the controller's
          #   `filterable_attributes`. Use this when a controller serves several actions that render
          #   different columns (e.g. cluster brokers vs configs), so each action can expose the
          #   fields it actually displays.
          # @return [Hash, Array, Lib::HashProxy] filtered results
          # @note It mutates the provided resources in place, so it must not be used on shared
          #   structures like the app routing.
          def filter(resources, fields: nil)
            # Filtering (search) is a Pro-only feature. In OSS we return the resources untouched so
            # inherited controllers keep working without applying any filtering.
            return resources unless ::Karafka.pro?

            # Expose the fields to the view so the filtering box can render the selector
            @filterable_fields = fields || self.class.filterable_attributes || []

            Lib::Filter.new(
              @params.current_filter,
              allowed_attributes: @filterable_fields,
              field: @params.current_filter_field
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
          def not_found!(resource_id = "")
            raise(::Karafka::Web::Errors::Ui::NotFoundError, resource_id)
          end
        end
      end
    end
  end
end
