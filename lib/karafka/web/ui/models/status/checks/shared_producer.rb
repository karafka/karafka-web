# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if the Web UI reports through an idempotent or transactional app producer.
            #
            # This is an independent, informational check. Sharing the producer is a valid setup,
            # but a fatal error on such a producer affects all of its dispatches, the Web UI
            # reports included, so users may prefer a dedicated Web UI producer.
            class SharedProducer < Base
              independent!

              # Executes the shared producer check.
              #
              # @return [Status::Step] info when the default Web UI producer wraps an idempotent
              #   or transactional `Karafka.producer`, success otherwise
              def call
                # A producer set in the Web UI config is the user's explicit choice
                return step(:success) unless ::Karafka::Web.config.producer.instance_of?(
                  ::Karafka::Web::Producer
                )

                producer = ::Karafka.producer

                return step(:info, { type: "transactional" }) if producer.transactional?
                return step(:info, { type: "idempotent" }) if producer.idempotent?

                step(:success)
              end
            end
          end
        end
      end
    end
  end
end
