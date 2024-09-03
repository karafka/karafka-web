# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      # Base Roda application
      class Base < Roda
        include Helpers::PathsHelper
        include Helpers::ApplicationHelper
        include Helpers::TailwindHelper

        # Details that need to be evaluated in the context of OSS or Pro web UI.
        # If those would be evaluated in the base, they would not be initialized as expected
        CONTEXT_DETAILS = lambda do
          plugin(
            :public,
            root: Karafka::Web.gem_root.join('lib/karafka/web/ui/public'),
            # Cache all static files for the end user for as long as possible
            # We can do it because we ship per version assets so they invalidate with gem bumps
            headers: { 'Cache-Control' => 'max-age=31536000, immutable' },
            gzip: true,
            brotli: true
          )
          plugin :render_each
          plugin :partials
          # The secret here will be reconfigured after Web UI configuration setup
          # This is why we assign here a random value as it will have to be changed by the end
          # user to make the Web UI work.
          plugin :sessions, key: '_karafka_session', secret: SecureRandom.hex(64)
          plugin :route_csrf
        end

        plugin :render, escape: true, engine: 'erb'
        plugin :run_append_slash
        plugin :error_handler
        plugin :not_found
        plugin :hooks
        plugin :flash
        plugin :path
        plugin :capture_erb
        plugin :content_for
        plugin :inject_erb

        # Based on
        # https://github.com/sidekiq/sidekiq/blob/ae6ca119/lib/sidekiq/web/application.rb#L8
        plugin :content_security_policy do |csp|
          csp.default_src "'self' https: http:"
          csp.child_src "'self'"
          csp.connect_src "'self' https: http: wss: ws:"
          csp.font_src "'self' https: http:"
          csp.frame_src "'self'"
          csp.img_src "'self' https: http: data:"
          csp.manifest_src "'self'"
          csp.media_src "'self'"
          csp.object_src "'none'"
          csp.script_src "'self' https: http:"
          csp.style_src "'self' https: http: 'unsafe-inline'"
          csp.worker_src "'self'"
          csp.base_uri "'self'"
        end

        plugin :custom_block_results

        handle_block_result Controllers::Responses::Render do |result|
          render_response(result)
        end

        # Redirect either to referer back or to the desired path
        handle_block_result Controllers::Responses::Redirect do |result|
          # Map redirect flashes (if any) to Roda flash messages
          result.flashes.each { |key, value| flash[key] = value }

          response.redirect result.back? ? request.referer : root_path(result.path)
        end

        handle_block_result Controllers::Responses::File do |result|
          response.headers['Content-Type'] = 'application/octet-stream'
          response.headers['Content-Disposition'] = "attachment; filename=\"#{result.file_name}\""
          response.write result.content
        end

        # Display appropriate error specific to a given error type
        plugin :error_handler, classes: [
          ::Rdkafka::RdkafkaError,
          Errors::Ui::NotFoundError,
          Errors::Ui::ProOnlyError,
          Errors::Ui::ForbiddenError
        ] do |e|
          @error = true

          case e
          when Errors::Ui::ProOnlyError
            response.status = 402
            view 'shared/exceptions/pro_only'
          when Errors::Ui::ForbiddenError
            response.status = 403
            view 'shared/exceptions/not_allowed'
          else
            response.status = 404
            view 'shared/exceptions/not_found'
          end
        end

        not_found do
          @error = true
          response.status = 404
          view 'shared/exceptions/not_found'
        end

        before do
          check_csrf!
        end

        plugin :class_matchers

        # Time matcher with optional hours, minutes and seconds
        TIME_MATCHER = %r{(\d{4}-\d{2}-\d{2}/?(\d{2})?(:\d{2})?(:\d{2})?)}

        private_constant :TIME_MATCHER

        # Match a date-time. Useful for time-related routes
        # @note In case the date-time is invalid, raise and render 404
        # @note The time component is optional as `Time#parse` will fallback to lowest time
        #   available, so we can build only date based lookups
        class_matcher(Time, TIME_MATCHER) do |datetime|
          [Time.parse(datetime)]
        rescue ArgumentError
          raise Errors::Ui::NotFoundError
        end

        # Allows us to build current path with additional params + it merges existing params into
        # the query data. Query data takes priority over request params.
        # @param query_data [Hash] query params we want to add to the current path
        path :current do |query_data = {}|
          # Merge existing request parameters with new query data
          merged_params = deep_merge(request.params, query_data)

          # Flatten the merged parameters
          flattened_params = flatten_params('', merged_params)

          # Build the query string from the flattened parameters
          query_string = URI.encode_www_form(flattened_params)

          # Construct the full path with query string
          [request.path, query_string].compact.join('?')
        end

        # Sets appropriate template variables based on the response object and renders the
        # expected view
        # @param response [Karafka::Web::Ui::Controllers::Responses::Data] response data object
        def render_response(response)
          response.attributes.each do |key, value|
            instance_variable_set(
              "@#{key}", value
            )
          end

          view(response.path)
        end

        # @return [Karafka::Web::Ui::Controllers::Requests::Params] curated params
        def params
          Controllers::Requests::Params.new(request.params)
        end
      end
    end
  end
end
