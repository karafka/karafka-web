# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Helpers
        # Helpers for rendering the errors views
        module ErrorsHelper
          # Backtrace frames that come from gems or Ruby itself. Error reports strip the app root
          # and the gem home, so depending on `GEM_HOME` a gem frame starts with `gems/` or with
          # the gem directory (`karafka-2.5.0/`, or `karafka-a1b2c3d4e5f6/` for a git gem). Thread
          # backtraces keep absolute paths; the main thread ends in an executable such as `bundle`,
          # a `karafka` binstub or a version manager shim, all living in a `bin/` directory. JRuby
          # core frames are Java classes or JRuby kernel files.
          GEM_OR_RUBY_FRAME_REGEXP = %r{
            (\A|/)gems/
            | \A[^/\s]+-\d+(\.\d+)*[^/\s]*/
            | \A[^/\s]+-\h{12}/
            | \A<internal:
            | /lib/ruby/
            | /bin/[^/\s]+:\d
            | \Auri:classloader:
            | \.java:\d
          }x

          private_constant :GEM_OR_RUBY_FRAME_REGEXP

          # The errors topic can also receive foreign or malformed messages (for example one a
          # user published to it by mistake). Returns the deserialized error payload only when it
          # is one of our own error reports (identified by the `schema_version` all of them carry);
          # otherwise `nil`, so the views can fall back to a placeholder instead of raising and
          # 500-ing the whole page.
          #
          # @param message [::Karafka::Web::Ui::Models::Message, Array] an error message or a
          #   compacted-offset marker (an array)
          # @return [Hash, false] the error payload when it is one of our reports, otherwise `false`
          def displayable_error(message)
            return false if message.is_a?(Array)

            payload = message.payload

            return false unless payload.is_a?(Hash) && payload[:schema_version]

            payload
          # A foreign payload can fail to deserialize (invalid JSON, or a corrupt zlib body); those
          # should not take the whole page down. Anything else is a real bug, so let it raise.
          rescue JSON::ParserError, Zlib::Error
            false
          end

          # @param status [Integer] librdkafka message persistence status
          # @return [String] human readable status
          def delivery_status_name(status)
            case status
            when ::Rdkafka::Bindings::RD_KAFKA_MSG_STATUS_PERSISTED
              "persisted"
            when ::Rdkafka::Bindings::RD_KAFKA_MSG_STATUS_POSSIBLY_PERSISTED
              "possibly persisted"
            when ::Rdkafka::Bindings::RD_KAFKA_MSG_STATUS_NOT_PERSISTED
              "not persisted"
            else
              status.to_s
            end
          end

          # Gem and Ruby frames are muted so the application frames stand out without any extra
          # styling of their own, which would dominate backtraces made mostly of application code
          #
          # @param frame [String] one backtrace line
          # @return [Boolean] is this a gem or Ruby frame that should be muted
          def backtrace_frame_muted?(frame)
            frame.match?(GEM_OR_RUBY_FRAME_REGEXP)
          end

          # Renders one backtrace frame. Gem and Ruby frames are muted and the given paths prefix
          # is wrapped so it can be collapsed. The ellipsis shown instead of it comes from css, so
          # copying a collapsed backtrace still copies the full paths.
          #
          # @param frame [String] one backtrace line
          # @param prefix [String, nil] shared paths prefix to make collapsible
          # @return [String] escaped frame html
          def backtrace_frame(frame, prefix = nil)
            html = if prefix && frame.start_with?(prefix)
              %(<span class="backtrace-prefix">#{::Rack::Utils.escape_html(prefix)}</span>) +
                %(<span class="backtrace-ellipsis"></span>) +
                ::Rack::Utils.escape_html(frame.delete_prefix(prefix))
            else
              ::Rack::Utils.escape_html(frame)
            end

            backtrace_frame_muted?(frame) ? %(<span class="text-muted">#{html}</span>) : html
          end

          # Finds the directory prefix shared by the absolute paths of the application frames, so
          # it can be collapsed instead of repeating in every frame. Gem and Ruby frames are left
          # out because they often live under a different root and would shrink the prefix to `/`.
          #
          # @param backtraces [Array<String>] backtraces with one frame per line
          # @return [String, nil] shared directory prefix (ending with `/`) or nil when there is
          #   no prefix worth collapsing
          def backtrace_paths_prefix(*backtraces)
            directories = backtraces
              .flat_map { |backtrace| backtrace.to_s.lines(chomp: true) }
              .select { |frame| frame.start_with?("/") && !backtrace_frame_muted?(frame) }
              .map { |frame| frame[%r{\A[^:]*/}] }
              .compact

            return nil if directories.size < 2

            prefix = directories.reduce do |common, directory|
              common = common.chop until directory.start_with?(common)
              common
            end

            prefix = prefix[%r{\A.*/}]

            # Collapsing only `/` or a single top directory would not make frames any shorter
            (prefix && prefix.count("/") > 2) ? prefix : nil
          end
        end
      end
    end
  end
end
