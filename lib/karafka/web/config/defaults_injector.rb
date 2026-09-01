# frozen_string_literal: true

module Karafka
  module Web
    class Config
      # Injects Web UI specific kafka settings into a kafka config hash, applying each setting
      # only when it is not already present in that hash.
      #
      # This mirrors `Karafka::Setup::DefaultsInjector`: the values a caller passes explicitly
      # always win, and the Web UI ones are only filled in for keys the caller did not set. Pro
      # can layer additional defaults on top by prepending a module onto the singleton class and
      # calling `super`.
      #
      # The defaults come straight from `config.ui.kafka`, so whatever the user configures there
      # is what gets injected into Web UI admin operations.
      class DefaultsInjector < Karafka::Core::Configurable::Injector
        class << self
          # @return [Hash] Web UI specific kafka settings used as defaults
          def defaults
            Karafka::Web.config.ui.kafka
          end
        end
      end
    end
  end
end
