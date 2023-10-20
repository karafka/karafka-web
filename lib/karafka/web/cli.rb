# frozen_string_literal: true

module Karafka
  module Web
    # Web CLI
    class Cli < Karafka::Cli
      class << self
        private

        # @return [Array<Class>] command classes
        def commands
          Base.commands
        end
      end
    end
  end
end
