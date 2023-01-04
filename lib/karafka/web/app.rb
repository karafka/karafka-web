# frozen_string_literal: true

module Karafka
  module Web
    # Proxy App that selects either Pro or regular app to handle the requests
    class App
      class << self
        # @param env [Hash] Rack env
        # @param block [Proc] Rack block
        def call(env, &block)
          handler = Karafka.pro? ? Ui::Pro::App : Ui::App
          handler.call(env, &block)
        end
      end
    end
  end
end
