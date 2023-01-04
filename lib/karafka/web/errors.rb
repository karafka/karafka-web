# frozen_string_literal: true

module Karafka
  module Web
    # Karafka::Web related errors
    module Errors
      # Tracking related errors
      module Tracking
        # Raised when the a report is not valid for any reason
        # This should never happen and if you see this, please open an issue.
        ContractError = Class.new(::Karafka::Errors::BaseError)
      end

      # Ui related errors
      module Ui
        # Raised when we cannot display a given view.
        # This may mean, that request topic was not present or partition or a message.
        NotFoundError = Class.new(::Karafka::Errors::BaseError)

        # Raised whe a given feature is available for Pro but not pro used
        ProOnlyError = Class.new(::Karafka::Errors::BaseError)
      end
    end
  end
end
