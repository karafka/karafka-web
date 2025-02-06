# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        # Encapsulates the command request details not to use a raw hash
        class Request
          # @param details [Hash] raw request details
          def initialize(details)
            @details = details
          end

          # @return [String] name of the request
          def name
            self[:name]
          end

          # Fetches the underlying details value and raises key error when not available
          #
          # @param key [Symbol]
          # @return [Object]
          # @raise [KeyError]
          def [](key)
            @details.fetch(key)
          end

          # @return [Hash] raw details
          def to_h
            @details
          end
        end
      end
    end
  end
end
