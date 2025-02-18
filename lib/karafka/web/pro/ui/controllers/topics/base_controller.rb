# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          # Namespace for all the controllers related to working with topics
          module Topics
            # Base controller for all topics related controllers
            class BaseController < Controllers::BaseController
              # @param args [Object] arguments accepted by the base controller
              def initialize(*args)
                super

                @management_active = Karafka::Web.config.ui.topics.management.active
              end

              private

              # Allows certain action only when topics management is active
              def only_with_management_active!
                return if @management_active

                raise Errors::Ui::ForbiddenError
              end
            end
          end
        end
      end
    end
  end
end
