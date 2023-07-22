# frozen_string_literal: true

module Karafka
  module Web
    # Karafka::Web related errors
    module Errors
      # Base class for all errors related to the web ui
      BaseError = Class.new(::Karafka::Errors::BaseError)

      # Processing related errors namespace
      module Processing
        # Raised when we try to process reports but we do not have the current state bootstrapped
        # If you see this error, it probably means, that you did not bootstrap Web-UI correctly
        MissingCurrentStateError = Class.new(BaseError)
      end

      # Tracking related errors
      module Tracking
        # Raised when the a report is not valid for any reason
        # This should never happen and if you see this, please open an issue.
        ContractError = Class.new(BaseError)
      end

      # Ui related errors
      module Ui
        # Raised when we cannot display a given view.
        # This may mean, that request topic was not present or partition or a message.
        NotFoundError = Class.new(BaseError)

        # Raised whe a given feature is available for Pro but not pro used
        ProOnlyError = Class.new(BaseError)
      end
    end
  end
end
