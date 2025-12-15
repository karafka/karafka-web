# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        class Matcher
          # Namespace for sub-matcher implementations
          module Matchers
          end
        end
      end
    end
  end
end

require_relative 'matchers/base'
require_relative 'matchers/consumer_group_id'
require_relative 'matchers/topic'
