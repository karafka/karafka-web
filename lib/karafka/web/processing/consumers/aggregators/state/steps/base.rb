# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Aggregators
          class State
            # Namespace for all individual `State` pipeline step classes.
            #
            # Each step is a small, isolated class that enriches the shared `Context` in place.
            # Unlike `Ui::Models::Status::Checks`, steps here are unconditional and strictly
            # ordered (see `State::STEPS`) - there is no dependency/halting DSL, each step just
            # mutates the context so the next step sees the enriched result.
            module Steps
              # Base class for all `State` pipeline steps.
              class Base
                # @param context [State::Context] the shared context to enrich
                def initialize(context)
                  @context = context
                end

                # Executes the step, mutating `context` in place.
                #
                # Subclasses must implement this method.
                def call
                  raise NotImplementedError, "Implement this in a subclass"
                end

                private

                # @return [State::Context] the shared context
                attr_reader :context
              end
            end
          end
        end
      end
    end
  end
end
