# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        # Namespace for commands the process can react to
        module Commands
          module Consumers
            # Collects all backtraces from the available Ruby threads and publishes their details
            #   back to Kafka for debug.
            class Trace < Base
              self.id = 'consumers.trace'

              # Runs tracing and publishes result back to Kafka
              def call
                threads = {}

                Thread.list.each do |thread|
                  tid = (thread.object_id ^ ::Process.pid).to_s(36)
                  t_d = threads[tid] = {}
                  t_d[:label] = "Thread TID-#{tid} #{thread.name}"
                  t_d[:backtrace] = (thread.backtrace || ['<no backtrace available>']).join("\n")
                end

                Dispatcher.result(threads, process_id, id)
              end
            end
          end
        end
      end
    end
  end
end
