# frozen_string_literal: true

# @see https://github.com/mperham/sidekiq/blob/main/lib/sidekiq/web/helpers.rb
module Karafka
  module Web
    module Ui
      # Namespace for helpers used by the Web UI
      module Helpers
        # Main application helper
        module ApplicationHelper
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
            scope = request.path.delete_prefix(root_path).split('/')[0]

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

          # Renders tags one after another
          #
          # @param tags_array [Array<String>]
          # @return [String] tags badges
          def tags(tags_array)
            tags_array
              .map { |tag| %(<span class="badge bg-info">#{tag}</span>) }
              .join(' ')
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
          # @param delimiter [String] delimiter (comma by default)
          # @return [String] number with delimiter
          def number_with_delimiter(number, delimiter = ',')
            return '' unless number

            parts = number.to_s.to_str.split('.')
            parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
            parts.join('.')
          end

          # @param time [Float] UTC time float
          # @return [String] relative time tag for timeago.js
          def relative_time(time)
            stamp = Time.at(time).getutc.iso8601(3)
            %(<time class="ltr" dir="ltr" title="#{stamp}" datetime="#{stamp}">#{time}</time>)
          end

          # @param time [Time] time object we want to present with detailed ms label
          # @return [String] span tag with raw timestamp as a title and time as a value
          def time_with_label(time)
            stamp = (time.to_f * 1000).to_i

            %(<span title="#{stamp}">#{time}</span>)
          end

          # @param state [String] poll state
          # @param state_ch [Integer] time until next change of the poll state
          #   (from paused to active)
          # @return [String] span tag with label and title with change time if present
          def poll_state_with_change_time_label(state, state_ch)
            year_in_seconds = 131_556_926
            state_ch_in_seconds = state_ch / 1_000.0

            # If state is active, there is no date of change
            if state == 'active'
              %(
                <span class="badge #{kafka_state_bg(state)} mt-1 mb-1">#{state}</span>
              )
            elsif state_ch_in_seconds > year_in_seconds
              %(
                <span
                  class="badge #{kafka_state_bg(state)} mt-1 mb-1"
                  title="until manual resume"
                >
                  #{state}
                </span>
              )
            else
              %(
                <span
                  class="badge #{kafka_state_bg(state)} time-title mt-1 mb-1"
                  title="#{Time.now + state_ch_in_seconds}"
                >
                  #{state}
                </span>
              )
            end
          end

          # @param lag [Integer] lag
          # @return [String] lag if correct or `N/A` with labeled explanation
          # @see #offset_with_label
          def lag_with_label(lag)
            if lag.negative?
              title = 'Not available until first offset commit'
              %(<span class="badge bg-secondary" title="#{title}">N/A</span>)
            else
              lag.to_s
            end
          end

          # @param topic_name [String] name of the topic for explorer path
          # @param partition_id [Integer] partition for the explorer path
          # @param offset [Integer] offset
          # @param explore [Boolean] should we generate (when allowed) a link to message explorer
          # @return [String] offset if correct or `N/A` with labeled explanation for offsets
          #   that are less than 0. Offset with less than 0 indicates, that the offset was not
          #   yet committed and there is no value we know of
          def offset_with_label(topic_name, partition_id, offset, explore: false)
            if offset.negative?
              title = 'Not available until first offset commit'
              %(<span class="badge bg-secondary" title="#{title}">N/A</span>)
            elsif explore
              path = explorer_path(topic_name, partition_id, offset)
              %(<a href="#{path}">#{offset}</a>)
            else
              offset.to_s
            end
          end

          # @param details [::Karafka::Web::Ui::Models::Partition] partition information with
          #   lso risk state info
          # @return [String] background classes for row marking
          def lso_risk_state_bg(details)
            case details.lso_risk_state
            when :active
              ''
            when :at_risk
              'bg-warning bg-opacity-25'
            when :stopped
              'bg-danger bg-opacity-25'
            else
              raise ::Karafka::Errors::UnsupportedCaseError
            end
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

          # @param hash [Hash] we want to flatten
          # @param parent_key [String] key for recursion
          # @param result [Hash] result for recursion
          # @return [Hash]
          def flat_hash(hash, parent_key = nil, result = {})
            hash.each do |key, value|
              current_key = parent_key ? "#{parent_key}.#{key}" : key.to_s
              if value.is_a?(Hash)
                flat_hash(value, current_key, result)
              elsif value.is_a?(Array)
                value.each_with_index do |item, index|
                  flat_hash({ index => item }, current_key, result)
                end
              else
                result[current_key] = value
              end
            end

            result
          end

          # @param name [String] link value
          # @param attribute [Symbol, nil] sorting attribute or nil if we provide only symbol name
          # @param rev [Boolean] when set to true, arrows will be in the reverse position. This is
          #   used when the description in the link is reverse to data we sort. For example we have
          #   order on when processes were started and we display "x hours" ago but we sort on
          #   their age, meaning that it looks like it is the other way around. This flag allows
          #   us to reverse just he arrow making it look consistent with the presented data order
          # @return [String] html link for sorting with arrow when attribute sort enabled
          def sort_link(name, attribute = nil, rev: false)
            unless attribute
              attribute = name
              name = attribute.to_s.tr('_', ' ').capitalize
            end

            arrow_both = '&#x21D5;'
            arrow_down = '&#9662;'
            arrow_up = '&#9652;'

            desc = "#{attribute} desc"
            asc = "#{attribute} asc"
            path = current_path(sort: desc)
            full_name = "#{name}&nbsp;#{arrow_both}"

            if params.sort == desc
              path = current_path(sort: asc)
              full_name = "#{name}&nbsp;#{rev ? arrow_up : arrow_down}"
            end

            if params.sort == asc
              path = current_path(sort: desc)
              full_name = "#{name}&nbsp;#{rev ? arrow_down : arrow_up}"
            end

            "<a class=\"sort\" href=\"#{path}\">#{full_name}</a>"
          end
        end
      end
    end
  end
end
