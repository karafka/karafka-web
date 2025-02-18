# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

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

          setting :listeners, default: [
            Handlers::Partitions::Listener.new
          ]

          configure
        end
      end
    end
  end
end
