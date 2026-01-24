# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          module Policies
            # Allows for a granular control over what parts of messages are being displayed and
            # operated on.
            # There are scenarios where payload or other parts of messages should not be presented
            # because they may contain sensitive data. This API allows to manage that on a per
            # message basis.
            class Messages
              # @param _message [::Karafka::Messages::Message]
              # @return [Boolean] should message key be visible
              def key?(_message)
                true
              end

              # @param _message [::Karafka::Messages::Message]
              # @return [Boolean] should message headers be visible
              def headers?(_message)
                true
              end

              # @param message [::Karafka::Messages::Message]
              # @return [Boolean] should message payload be visible
              def payload?(message)
                !message.headers.key?('encryption')
              end

              # Should it be allowed to download this message raw payload
              #
              # @param message [::Karafka::Messages::Message]
              # @return [Boolean] true if downloads allowed
              def download?(message)
                payload?(message)
              end

              # Should it be allowed to download the deserialized and sanitized payload as JSON
              #
              # @param message [::Karafka::Messages::Message]
              # @return [Boolean] true if exports allowed
              def export?(message)
                payload?(message)
              end

              # Should we allow to republish given message
              #
              # @param _message [::Karafka::Messages::Message]
              # @return [Boolean] true if we should allow republishing
              # @note This is a simple API that does not provide granular republishing support.
              #   You can decide whether to allow for republishing but you cannot say "allow only
              #   to X", etc.
              def republish?(_message)
                true
              end
            end
          end
        end
      end
    end
  end
end
