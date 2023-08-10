# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      # Non info related extra components used in the UI
      module Lib
        # Ttl Cache for caching things in-memory
        # @note It **is** thread-safe
        class TtlCache
          include ::Karafka::Core::Helpers::Time

          # @param ttl [Integer] time in ms how long should this cache keep data
          def initialize(ttl)
            @ttl = ttl
            @times = {}
            @values = {}
            @mutex = Mutex.new
          end

          # Reads data from the cache
          #
          # @param key [String, Symbol] key for the cache read
          # @return [Object] anything that was cached
          def read(key)
            @mutex.synchronize do
              evict
              @values[key]
            end
          end

          # Writes to the cache
          #
          # @param key [String, Symbol] key for the cache
          # @param value [Object] value we want to cache
          # @return [Object] value we have written
          def write(key, value)
            @mutex.synchronize do
              @times[key] = monotonic_now + @ttl
              @values[key] = value
            end
          end

          # Reads from the cache and if value not present, will run the block and store its result
          # in the cache
          #
          # @param key [String, Symbol] key for the cache read
          # @return [Object] anything that was cached or yielded
          def fetch(key)
            @mutex.synchronize do
              evict

              return @values[key] if @values.key?(key)

              @values[key] = yield
            end
          end

          # Clears the whole cache
          def clear
            @mutex.synchronize do
              @times.clear
              @values.clear
            end
          end

          private

          # Removes expired elements from the cache
          def evict
            @times.each do |key, time|
              next if time >= monotonic_now

              @times.delete(key)
              @values.delete(key)
            end
          end
        end
      end
    end
  end
end
