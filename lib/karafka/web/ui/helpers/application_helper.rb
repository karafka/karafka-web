# frozen_string_literal: true

# @see https://github.com/mperham/sidekiq/blob/main/lib/sidekiq/web/helpers.rb
module Karafka
  module Web
    module Ui
      # Namespace for helpers used by the Web UI
      module Helpers
        # Main application helper
        module ApplicationHelper
          # Generates a full path with the root path out of the provided arguments
          #
          # @param args [Array<String, Numeric>] arguments that will make the path
          # @return [String] path from the root
          #
          # @note This needs to be done that way with the `#root_path` because the web UI can be
          #   mounted in a sub-path and we need to make sure our all paths are relative to "our"
          #   root, not the root of the app in which it was mounted.
          def root_path(*args)
            "#{env.fetch('SCRIPT_NAME')}/#{args.join('/')}"
          end

          # Adds active class to the current location in the nav if needed
          # @param location [Hash]
          def nav_class(location)
            comparator, value = location.to_a.first

            local_location = request.path.gsub(env.fetch('SCRIPT_NAME'), '')
            local_location.public_send(:"#{comparator}?", value) ? 'active' : ''
          end

          # Converts object into a string and for objects that would anyhow return their
          # stringified instance value, it replaces it with the class name instead.
          # Useful for deserializers, etc presentation.
          #
          # @param object [Object]
          # @return [String]
          def object_value_to_s(object)
            object.to_s.include?('#<') ? object.class.to_s : object.to_s
          end

          # Renders per scope breadcrumbs
          def render_breadcrumbs
            scope = request.path.gsub(root_path, '').split('/')[0]

            render "#{scope}/_breadcrumbs"
          end

          # Takes a status and recommends background style color
          #
          # @param status [String] status
          # @return [String] background style
          def status_bg(status)
            case status
            when 'initialized' then 'bg-success'
            when 'running' then 'bg-success'
            when 'quieting' then 'bg-warning'
            when 'quiet' then 'bg-warning text-dark'
            when 'stopping' then 'bg-warning text-dark'
            when 'stopped' then 'bg-danger'
            else
              raise ::Karafka::Errors::UnsupportedCaseError, status
            end
          end

          # Takes the lag trend and gives it appropriate background style color for badge
          #
          # @param trend [Numeric] lag trend
          # @return [String] bg classes
          def lag_trend_bg(trend)
            bg = 'bg-success' if trend.negative?
            bg ||= 'bg-warning text-dark' if trend.positive?
            bg ||= 'bg-secondary'
            bg
          end

          # Takes a kafka report state and recommends background style color
          # @param state [String] state
          # @return [String] background style
          def kafka_state_bg(state)
            case state
            when 'up' then 'bg-success text-white'
            when 'active' then 'bg-success text-white'
            when 'steady' then 'bg-success text-white'
            else
              'bg-warning text-dark'
            end
          end

          # @param mem_kb [Integer] memory used in KB
          # @return [String] formatted memory usage
          def format_memory(mem_kb)
            return '0' if !mem_kb || mem_kb.zero?

            if mem_kb < 10_240
              "#{number_with_delimiter(mem_kb)} KB"
            elsif mem_kb < 1_000_000
              "#{number_with_delimiter((mem_kb / 1024.0).to_i)} MB"
            else
              "#{number_with_delimiter((mem_kb / (1024.0 * 1024.0)).round(1))} GB"
            end
          end

          # Converts number to a more friendly delimiter based version
          # @param number [Numeric]
          # @return [String] number with delimiter
          def number_with_delimiter(number)
            return '' unless number

            parts = number.to_s.to_str.split('.')
            parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, '\1,')
            parts.join('.')
          end

          # @param time [Float] UTC time float
          # @return [String] relative time tag for timeago.js
          def relative_time(time)
            stamp = Time.at(time).getutc.iso8601
            %(<time class="ltr" dir="ltr" title="#{stamp}" datetime="#{stamp}">#{time}</time>)
          end

          # Returns the view title html code
          #
          # @param title [String] page title
          # @param hr [Boolean] should we add the hr tag at the end
          # @return [String] title html
          def view_title(title, hr: false)
            <<-HTML
              <div class="container mb-5">
                <div class="row">
                  <h3>
                    #{title}
                  </h3>
                </div>

                #{hr ? '<hr/>' : ''}
              </div>
            HTML
          end
        end
      end
    end
  end
end
