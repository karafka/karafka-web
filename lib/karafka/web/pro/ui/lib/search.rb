# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          # All code needed to support the search functionality
          # It's not in models because it does not provide "data" per se but rather fetches it
          # from a Kafka.
          module Search
            class << self
              # Validates that the UI search config is correct
              #
              # @param config [Karafka::Core::Configurable::Node] web config
              def post_setup(config)
                Search::Contracts::Config.new.validate!(config.to_h)
              end
            end
          end
        end
      end
    end
  end
end
