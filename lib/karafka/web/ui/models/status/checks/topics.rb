# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        class Status
          module Checks
            # Checks if all required Web UI topics exist in the Kafka cluster.
            #
            # The Web UI requires several topics to function:
            # - consumers states topic
            # - consumers reports topic
            # - consumers metrics topic
            # - errors topic
            class Topics < Base
              depends_on :connection

              class << self
                # @return [Hash] empty hash for halted state
                def halted_details
                  {}
                end
              end

              # Executes the topics check.
              #
              # Verifies that all required topics exist by checking the cluster info
              # cached in the context.
              #
              # @return [Status::Step] result with topic details
              def call
                details = context.topics_details
                status = (details.all? { |_, detail| detail[:present] }) ? :success : :failure

                step(status, details)
              end
            end
          end
        end
      end
    end
  end
end
