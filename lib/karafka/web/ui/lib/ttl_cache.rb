# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      # Non info related extra components used in the UI
      module Lib
        class TtlCache
          include ::Karafka::Core::Helpers::Time

          def initialize(ttl)
            @ttl = ttl
            @times = {}
            @values = {}
            @mutex = Mutex.new
          end

          def read(key)
            @mutex.synchronize do
              evict
              @values[key]
            end
          end

          def write(key, value)
            @mutex.synchronize do
              @times[key] = monotonic_now + @ttl
              @values[key] = value
            end
          end

          def fetch(key, value)
            @mutex.synchronize do
              evict

              return @values[key] if @values.key?(key)

              @values[key] = yield
            end
          end

          private

          def evict
            @times.each do |key, time|
              next if time >= monotonic_now

              @times.delete(key)
              delete(key)
            end
          end
        end
      end
    end
  end
end
