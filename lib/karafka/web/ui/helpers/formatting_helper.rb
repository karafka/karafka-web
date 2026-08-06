# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Helpers
        # Generic value, number and text formatting helpers used across the Web UI
        module FormattingHelper
          # Converts object into a string and for objects that would anyhow return their
          # stringified instance value, it replaces it with the class name instead.
          # Useful for deserializers, etc presentation.
          #
          # @param object [Object]
          # @return [String]
          def object_value_to_s(object)
            object.to_s.include?("#<") ? object.class.to_s : object.to_s
          end

          # @param mem_kb [Integer] memory used in KB
          # @return [String] formatted memory usage
          def format_memory(mem_kb)
            return "0" if !mem_kb || mem_kb.zero?

            if mem_kb < 10_240
              "#{number_with_delimiter(mem_kb.round(4))} KB"
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
          def number_with_delimiter(number, delimiter = ",")
            return "" unless number

            parts = number.to_s.to_str.split(".")
            parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
            parts.join(".")
          end

          # Truncates given text if it is too long and wraps it with a title with full text.
          # Can use a middle-based strategy that keeps beginning and ending of a string instead of
          # keeping just the beginning.
          #
          # The `:middle` strategy is useful when we have strings such as really long process names
          # that have important beginning and end but middle can be removed without risk of not
          # allowing user to recognize the content.
          #
          # @param string [String] string we want to truncate
          # @param length [Integer] max length of the final string that we accept before truncating
          # @param omission [String] truncation omission
          # @param strategy [Symbol] `:default` or `:middle` how should we truncate
          # @return [String] HTML span tag with truncated content and full content title
          def truncate(string, length: 50, omission: "...", strategy: :default)
            return string if string.length <= length

            case strategy
            when :default
              truncated = string[0...(length - omission.length)] + omission
            when :middle
              part_length = (length - omission.length) / 2
              truncated = string[0...part_length] + omission + string[-part_length..]
            else
              raise Karafka::Errors::UnsupportedCaseError, "Unknown strategy: #{strategy}"
            end

            %(<span title="#{string}">#{truncated}</span>)
          end
        end
      end
    end
  end
end
