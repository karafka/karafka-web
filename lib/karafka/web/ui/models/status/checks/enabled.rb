# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if karafka-web is enabled in the karafka.rb routing.
            #
            # This is the first check in the chain and verifies that the consumer group
            # for the Web UI is properly injected into the routing. Without this,
            # the Web UI cannot function.
            #
            # @note This check does NOT verify if the group is active because that may
            #   depend on configuration details. It only checks that the routing is
            #   aware of the deserializer and other Web UI requirements.
            class Enabled < Base
              independent!

              # Executes the enabled check.
              #
              # Looks for the Web UI consumer group in the Karafka routing.
              #
              # @return [Status::Step] success if the group is found, failure otherwise
              def call
                enabled = ::Karafka::App.routes.map(&:name).include?(
                  ::Karafka::Web.config.group_id
                )

                step(enabled ? :success : :failure)
              end
            end
          end
        end
      end
    end
  end
end
