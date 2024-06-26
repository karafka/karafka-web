# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

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
