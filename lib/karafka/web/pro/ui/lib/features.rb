# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          # Module that aliases our features in the UI for controllers and views to simplify
          # features checks
          module Features
            class << self
              # @return [Boolean] is commanding turned on
              def commanding?
                ::Karafka::Web.config.commanding.active
              end

              # Ensures that commanding is on.
              # @raise [Karafka::Web::Errors::Ui::ForbiddenError] raised when commanding is off
              def commanding!
                return if commanding?

                forbidden!
              end

              # @return [Boolean] is topics managements turned on
              def topics_management?
                Karafka::Web.config.ui.topics.management.active
              end

              # @raise [Karafka::Web::Errors::Ui::ForbiddenError] raised when topic management is
              #   off
              def topics_management!
                return if topics_management?

                forbidden!
              end

              private

              # Raises the forbidden error
              def forbidden!
                raise Errors::Ui::ForbiddenError
              end
            end
          end
        end
      end
    end
  end
end
