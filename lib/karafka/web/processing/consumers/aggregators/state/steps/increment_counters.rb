# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Aggregators
          class State
            module Steps
              # Increments the total counters based on the provided report.
              class IncrementCounters < Base
                # Increments `context.state[:stats]` totals from `context.report[:stats][:total]`
                def call
                  context.report[:stats][:total].each do |key, value|
                    context.state[:stats][key] ||= 0
                    context.state[:stats][key] += value
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
