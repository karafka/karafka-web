# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Controllers
        module Responses
          # Response that tells Roda to ship the content under a file name
          class File
            attr_reader :content, :file_name

            # @param content [String] data we want to send
            # @param file_name [String] name under which we want to send it
            def initialize(content, file_name)
              @content = content
              @file_name = file_name
            end
          end
        end
      end
    end
  end
end
