# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        module Responses
          # Representation of a redirect response with optional flash messages
          class Redirect
            attr_reader :path, :flashes

            # @param path [String, Symbol] relative (without root path) path where we want to be
            #   redirected or `:back` to use referer back
            # @param flashes [Hash] hash where key is the flash type and value is the message
            def initialize(path = :back, flashes = {})
              @path = path
              @flashes = flashes
            end

            # @return [Boolean] are we going back via referer and not explicit path
            def back?
              @path == :back
            end
          end
        end
      end
    end
  end
end
