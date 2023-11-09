# frozen_string_literal: true

module Karafka
  module Web
    class Inflector < Zeitwerk::GemInflector
      def camelize(basename, abspath)
        if basename =~ /\A[0-9]+_(.*)/
          super($1, abspath)
        else
          super
        end
      end
    end
  end
end
