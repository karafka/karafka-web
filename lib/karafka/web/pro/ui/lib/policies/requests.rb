# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          module Policies
            # Per request policies setup class. Allows for writing low level policies that can
            # be used to block certain Web UI functionalities on the request level.
            class Requests
              # @param _env [Hash] rack env object that we can use to get request details
              # @return [Boolean] should this request be allowed or not
              # @note By default we do not limit anything in the Web UI, however particular
              #   granular policies may limit things on their own.
              def allow?(_env)
                true
              end
            end
          end
        end
      end
    end
  end
end
