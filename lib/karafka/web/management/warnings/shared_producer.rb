# frozen_string_literal: true

module Karafka
  module Web
    module Management
      # Namespace for checks that warn about risky but valid Web UI setups
      module Warnings
        # Warns when the Web UI reports through an idempotent or transactional app producer.
        # A fatal idempotence error on such a producer stops every dispatch made through it.
        class SharedProducer
          # Logged when the Web UI reports through an idempotent or transactional app producer
          MESSAGE = <<~MSG.tr("\n", " ").strip
            Karafka Web UI reports through the idempotent or transactional Karafka.producer.
            A fatal idempotence error on it (e.g. librdkafka "Unable to reconstruct MessageSet")
            stops all its dispatches: your application messages, the Karafka Web UI reports
            and anything else produced through Karafka.producer.
            Configure a dedicated Web UI producer to isolate them:
            https://karafka.io/docs/Web-UI-Configuration/#using-a-custom-web-ui-producer
          MSG

          private_constant :MESSAGE

          # Logs the warning when no custom Web UI producer is configured and the app producer is
          # idempotent or transactional
          def call
            return unless ::Karafka::Web.config.producer.instance_of?(::Karafka::Web::Producer)

            app_producer = ::Karafka.producer

            return unless app_producer.idempotent? || app_producer.transactional?

            ::Karafka.logger.warn(MESSAGE)
          end
        end
      end
    end
  end
end
