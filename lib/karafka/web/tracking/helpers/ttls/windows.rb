# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Helpers
        module Ttls
          # Object used to track process metrics in time windows. Those are shared, meaning they do
          # not refer to particular metric type but allow us to store whatever we want.
          #
          # We have following time windows:
          #   - m1 - one minute big
          #   - m5 - five minute big
          Windows = Struct.new(:m1, :m5) do
            # @return [Ttls::Windows]
            def initialize
              super(
                Ttls::Hash.new(60 * 1_000),
                Ttls::Hash.new(5 * 60 * 1_000)
              )
            end

            # Clears the TTLs windows
            def clear
              values.each(&:clear)
            end
          end
        end
      end
    end
  end
end
