# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        # Thread-safe in-memory cache with metadata tracking.
        #
        # This cache supports storing computed values, tracking the last update time,
        # and computing a hash of the contents for change detection.
        # It's designed for ephemeral, per-instance caching in Karafka Web controllers or libs.
        #
        # The cache ensures safe concurrent access via a mutex and provides utilities
        # for cache invalidation based on external session state (timestamp + hash).
        #
        # @note All cache operations are mutex-synchronized for thread safety.
        #
        # @note We do not have granular level caching because our Web UI cache is fairly simple
        #   and we do not want to overcomplicate things.
        class Cache
          # Initializes an empty cache instance
          # @param ttl_ms [Integer] time to live of the whole cache. After this time cache will be
          #   cleaned whether or not it is expired.
          def initialize(ttl_ms)
            @ttl_ms = ttl_ms
            @values = {}
            @timestamp = nil
            @hash = nil
            @mutex = Mutex.new
          end

          # Fetches or computes and stores a value under the given key.
          #
          # If the key already exists, returns the cached value.
          # Otherwise, computes it via the provided block, stores it,
          # and updates metadata (timestamp + hash).
          #
          # @param key [Object] key to retrieve
          # @yield block to compute the value if key is not present
          # @return [Object] cached or computed value
          def fetch(key)
            @mutex.synchronize do
              return @values[key] if @values.key?(key)

              @values[key] = yield
              @hash = Digest::SHA256.hexdigest(
                @values.sort.to_h.to_json
              )
              @timestamp = Time.now.to_f
              @values[key]
            end
          end

          # Clears the cache and resets metadata (timestamp and hash).
          #
          # If the mutex is already owned by the current thread, clears immediately.
          # Otherwise, synchronizes first.
          #
          # @return [void]
          def clear
            cleaning = lambda do
              @values.clear
              @timestamp = nil
              @hash = nil
            end

            return cleaning.call if @mutex.owned?

            @mutex.synchronize do
              cleaning.call
            end
          end

          # Checks whether any values have been cached yet
          #
          # @return [Boolean] true if the cache has been written to
          def exist?
            !timestamp.nil?
          end

          # Returns the last update timestamp of the cache
          #
          # @return [Integer, nil] Unix timestamp or nil if never set
          def timestamp
            @mutex.synchronize { @timestamp }
          end

          # Returns the hash representing the current cached data state
          #
          # @return [String, nil] SHA256 hex digest or nil if never set
          def hash
            @mutex.synchronize { @hash }
          end

          # Clears the cache if the provided session hash and timestamp differ
          #
          # This is used to invalidate the cache if the external session data indicates
          # a newer or inconsistent state.
          #
          # @param session_hash [String, nil] hash from the session or remote side
          # @param session_timestamp [Integer, nil] timestamp from the session
          # @return [Boolean] true if the cache was cleared, false otherwise
          def clear_if_needed(session_hash, session_timestamp)
            @mutex.synchronize do
              return unless should_refresh?(session_hash, session_timestamp)

              clear
            end
          end

          private

          # Determines whether the cache should be refreshed based on session data
          #
          # @param session_hash [String, nil]
          # @param session_timestamp [Integer, nil]
          # @return [Boolean] true if cache should be refreshed
          def should_refresh?(session_hash, session_timestamp)
            return true if @hash.nil? || @timestamp.nil?
            return true if session_hash.nil? || session_timestamp.nil?

            now = (Time.now.to_f * 1_000).to_i

            return true if now - (@timestamp * 1_000) > @ttl_ms

            return false if @hash == session_hash
            return false if @timestamp > session_timestamp

            true
          end
        end
      end
    end
  end
end
