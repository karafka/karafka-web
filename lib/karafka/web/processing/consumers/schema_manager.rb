# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        # Schema manager is responsible for making sure, that the consumers reports messages that
        # we consume have a compatible schema with the current process that is suppose to
        # materialize them.
        #
        # In general we always support at least one major version back and we recommend upgrades
        # to previous versions (0.5 => 0.6 => 0.7)
        #
        # This is needed in scenarios where a rolling deploy would get new karafka processes
        # reporting data but consumption would still run in older.
        class SchemaManager
          # Current reports version for comparing
          CURRENT_VERSION = ::Gem::Version.new(
            ::Karafka::Web::Tracking::Consumers::Sampler::SCHEMA_VERSION
          )

          private_constant :CURRENT_VERSION

          def initialize
            @cache = {}
            @valid = true
          end

          # @param message [Karafka::Messages::Message] consumer report
          # @return [Symbol] is the given message using older, newer or current schema
          def call(message)
            schema_version = message.payload[:schema_version]

            # Save on memory allocation by reusing
            # Most of the time we will deal with compatible schemas, so it is not worth creating
            # an object with each message
            message_version = @cache[schema_version] ||= ::Gem::Version.new(schema_version)

            return :older if message_version < CURRENT_VERSION
            return :newer if message_version > CURRENT_VERSION

            :current
          end

          # Moves the schema manager state to incompatible to indicate in the Web-UI that we
          # cannot move forward because schema is incompatible.
          #
          # @note The state switch is one-direction only. If we encounter an incompatible message
          #   we need to stop processing so further checks even with valid should not switch it
          #   back to valid
          def invalidate!
            @valid = false
          end

          # @return [String] state that we can use in the materialized state for the UI reporting
          def to_s
            @valid ? 'compatible' : 'incompatible'
          end
        end
      end
    end
  end
end
