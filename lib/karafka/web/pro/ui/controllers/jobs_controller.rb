# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Controllers
          # Displays list of active jobs
          class JobsController < Web::Ui::Controllers::JobsController
            self.sortable_attributes = %w[
              id
              topic
              consumer
              type
              messages
              first_offset
              last_offset
              committed_offset
              updated_at
            ].freeze
          end
        end
      end
    end
  end
end
