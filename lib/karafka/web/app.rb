# frozen_string_literal: true

module Karafka
  module Web
    # Proxy App that selects either Pro or regular app to handle the requests
    class App
      class << self
        # @param env [Hash] Rack env
        # @param block [Proc] Rack block
        def call(env, &block)
          engine.call(env, &block)
        end

        # @return [Class] regular or pro Web engine
        def engine
          ::Karafka.pro? ? Pro::Ui::App : Ui::App
        end
      end
    end
  end
end
