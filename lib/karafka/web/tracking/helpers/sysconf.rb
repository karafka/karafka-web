# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      # Namespace for tracking related helpers
      module Helpers
        # Namespace for unix-based helper methods used to fetch OS details
        module Sysconf
          extend FFI::Library

          case RUBY_PLATFORM
          when /linux/
            ffi_lib 'libc.so.6' # Standard C library on Linux
            SC_PAGESIZE = 30 # _SC_PAGESIZE constant
          when /darwin/
            ffi_lib 'libSystem.B.dylib' # Standard C library on macOS
            SC_PAGESIZE = 29 # _SC_PAGESIZE constant
          end

          attach_function :sysconf, [:int], :long

          class << self
            # @return [Integer]
            def page_size
              sysconf(SC_PAGESIZE)
            end
          end
        end
      end
    end
  end
end
