require 'fiddle'
require 'fiddle/import'

module Karafka
  module Web
    module Tracking
      # Namespace for tracking related helpers
      module Helpers
        module Sysconf
          extend Fiddle::Importer
          case RUBY_PLATFORM
          when /linux/
            dlload 'libc.so.6'       # Standard C library on Linux
            SC_PAGESIZE = 30    # _SC_PAGESIZE constant
          when /darwin/
            dlload 'libSystem.B.dylib' # Standard C library on macOS
            SC_PAGESIZE = 29    # _SC_PAGESIZE constant
          end

          extern 'long sysconf(int)'

          def self.page_size
            sysconf(SC_PAGESIZE)
          end
        end
      end
    end
  end
end
