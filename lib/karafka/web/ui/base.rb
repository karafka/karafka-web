# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      # Base Roda application
      class Base < Roda
        include Helpers::ApplicationHelper

        # Details that need to be evaluated in the context of OSS or Pro web UI.
        # If those would be evaluated in the base, they would not be initialized as expected
        CONTEXT_DETAILS = lambda do
          plugin(
            :static,
            %w[/javascripts /stylesheets /images],
            root: Karafka::Web.gem_root.join('lib/karafka/web/ui/public')
          )
          plugin :render_each
          plugin :partials
        end

        plugin :render, escape: true, engine: 'erb'
        plugin :run_append_slash
        plugin :error_handler
        plugin :not_found
        plugin :path

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
          csp.script_src "'self' https: http: 'unsafe-inline'"
          csp.style_src "'self' https: http: 'unsafe-inline'"
          csp.worker_src "'self'"
          csp.base_uri "'self'"
        end

        # Display appropriate error specific to a given error type
        plugin :error_handler, classes: [
          ::Karafka::Web::Errors::Ui::NotFoundError,
          ::Rdkafka::RdkafkaError,
          Errors::Ui::ProOnlyError
        ] do |e|
          @error = true

          if e.is_a?(Errors::Ui::ProOnlyError)
            view 'shared/exceptions/pro_only'
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

        # Allows us to build current path with additional params
        # @param query_data [Hash] query params we want to add to the current path
        path :current do |query_data = {}|
          q = query_data
              .select { |_, v| v }
              .map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }
              .join('&')

          [request.path, q].compact.delete_if(&:empty?).join('?')
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
