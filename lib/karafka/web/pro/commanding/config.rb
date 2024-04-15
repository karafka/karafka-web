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
      module Commanding
        # Extra configuration for pro commanding
        class Config
          extend ::Karafka::Core::Configurable

          # Management of processes is enabled by default
          setting :active, default: true

          # How long should we wait on command arrival before yielding. Having it too short will
          # cause unnecessary CPU cycles. Too long will make shutdown slower.
          setting :max_wait_time, default: 2_000

          # How long should we wait when an error occurs. Since this subscription is via the assign
          # API, we can just back-off and not care since we can always re-create the consumer on
          # issues. We always want to prevent a case where we would create new in a loop and
          # fail without backoff as this could overload the process.
          #
          # This should not happen often so waiting that long should not pose significant risks
          # and should not cause issues with the user-experience, since this is only commanding
          # connection
          setting :pause_timeout, default: 10_000

          # The underlying iterator requires specific settings, do not change this unless you know
          # what you area doing
          setting :kafka, default: {
            'enable.partition.eof': false,
            'auto.offset.reset': 'latest'
          }

          configure
        end
      end
    end
  end
end
