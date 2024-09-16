# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

module Karafka
  module Web
    module Pro
      module Commanding
        # Namespace for commands the process can react to
        module Commands
          # Collects all backtraces from the available Ruby threads and publishes their details
          #   back to Kafka for debug.
          class Trace < Base
            # Runs tracing and publishes result back to Kafka
            def call
              threads = {}

              Thread.list.each do |thread|
                tid = (thread.object_id ^ ::Process.pid).to_s(36)
                t_d = threads[tid] = {}
                t_d[:label] = "Thread TID-#{tid} #{thread.name}"
                t_d[:backtrace] = (thread.backtrace || ['<no backtrace available>']).join("\n")
              end

              Dispatcher.result(threads, process_id, 'trace')
            end
          end
        end
      end
    end
  end
end
