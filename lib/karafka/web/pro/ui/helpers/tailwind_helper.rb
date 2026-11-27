# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Ui
        module Helpers
          # Tailwind components of the Pro views
          module TailwindHelper
            # Renders an action that posts to the given path as a form with a submit button or,
            # when the action is not available, with a disabled one explaining why. The title sits
            # on the form, since disabled buttons do not receive pointer events. The form is middle
            # aligned like buttons, so it lines up with link buttons next to it.
            #
            # @param content [String] button html content (icon and label)
            # @param path [String] path the form posts to
            # @param classes [String] extra css classes of the button
            # @param title [String] title describing the action when available
            # @param disabled_reason [String, nil] why the action is not available or nil if it is
            # @return [String] action form html
            def action_form_button(content, path, classes:, title:, disabled_reason: nil)
              button_attributes = %(class="btn #{classes}")
              button_attributes = %(class="btn #{classes} btn-disabled" disabled) if disabled_reason

              %(<form action="#{path}" method="post" class="inline-flex items-center align-middle" ) +
                %(title="#{::Rack::Utils.escape_html(disabled_reason || title)}">) +
                %(<button type="submit" #{button_attributes}>#{content}</button></form>)
            end
          end
        end
      end
    end
  end
end
