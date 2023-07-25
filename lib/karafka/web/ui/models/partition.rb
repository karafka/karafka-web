# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Single topic partition data representation model
        class Partition < Lib::HashProxy
          # @return [Integer] lag
          # @note We check the presence because prior to schema version 1.2.0, this metrics was
          #   not reported from the processes
          def lag
            to_h.fetch(:lag, -1)
          end
        end
      end
    end
  end
end
