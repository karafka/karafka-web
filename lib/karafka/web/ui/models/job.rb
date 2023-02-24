# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Single job data representation model
        class Job < Lib::HashProxy
          # @return [Array<String>] tags of this consuming job / consumer
          def tags
            @hash[:tags] || []
          end
        end
      end
    end
  end
end
