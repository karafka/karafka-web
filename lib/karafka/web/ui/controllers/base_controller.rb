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
            #
            # It is either a flat list applied to every action, or a `{ action => fields }` hash
            # with an optional `:default` entry for controllers whose actions render different
            # columns (e.g. cluster brokers vs configs). See {#filterable_fields} for the
            # resolution.
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

          # Expose the fields the current action can be filtered on so the filtering box (and the
          # view-level filtering helpers) can render the field selector. Resolved from the
          # controller's `filterable_attributes` declaration on every request, so no action has to
          # wire this up by hand.
          before { @filterable_fields = filterable_fields }

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
          # fields allowed for filtering.
          #
          # The allowed fields default to `@filterable_fields`, which a before hook resolves from
          # the controller's `filterable_attributes` declaration for the current action and exposes
          # to the view. Pass `fields` only when the engine's match set must differ from the fields
          # shown in the selector (e.g. the health views scope the selector by topic/consumer group
          # but keyword-match against the leaf partition id); it overrides matching only and does
          # not change the exposed selector.
          #
          # @param resources [Hash, Array, Lib::HashProxy] object for filtering
          # @param fields [Array<Symbol>, nil] explicit engine allow-list for matching, overriding
          #   `@filterable_fields`
          # @return [Hash, Array, Lib::HashProxy] filtered results
          # @note It mutates the provided resources in place, so it must not be used on shared
          #   structures like the app routing.
          def filter(resources, fields: nil)
            # Filtering (search) is a Pro-only feature. In OSS we return the resources untouched so
            # inherited controllers keep working without applying any filtering.
            return resources unless ::Karafka.pro?

            Lib::Filter.new(
              @params.current_filter,
              allowed_attributes: fields || @filterable_fields,
              field: @params.current_filter_field
            ).call(resources)
          end

          # Resolves the fields the current action can be filtered on from the controller's
          # `filterable_attributes` declaration. The declaration is either a flat list (applied to
          # every action) or a `{ action => fields }` hash with an optional `:default` entry used
          # for the actions not listed explicitly.
          #
          # @return [Array<Symbol>, Array<String>] fields for the current action (empty when the
          #   action is not filterable)
          def filterable_fields
            attributes = self.class.filterable_attributes

            return Array(attributes) unless attributes.is_a?(Hash)

            Array(attributes[@current_action_name] || attributes[:default])
          end

          # Flattens a nested hash into a single-level hash with dotted keys, so nested settings can
          # be presented (and sorted/filtered) as a flat list of name/value rows.
          #
          # @param hash [Hash] hash we want to flatten
          # @param prefix [String, nil] key prefix used during recursion
          # @param result [Hash] accumulator used during recursion
          # @return [Hash] flattened `{ "a.b.c" => value }` hash
          def flatten_hash(hash, prefix = nil, result = {})
            hash.each do |key, value|
              flat_key = prefix ? "#{prefix}.#{key}" : key.to_s

              case value
              when Hash
                flatten_hash(value, flat_key, result)
              when Array
                value.each_with_index { |item, index| flatten_hash({ index => item }, flat_key, result) }
              else
                result[flat_key] = value
              end
            end

            result
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
