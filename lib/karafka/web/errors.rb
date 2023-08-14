# frozen_string_literal: true

module Karafka
  module Web
    # Karafka::Web related errors
    module Errors
      # Base class for all errors related to the web ui
      BaseError = Class.new(::Karafka::Errors::BaseError)

      # Raised when the a report is not valid for any reason
      # This should never happen and if you see this, please open an issue.
      ContractError = Class.new(BaseError)

      # Processing related errors namespace
      module Processing
        # Raised when we try to process reports but we do not have the current state bootstrapped
        # If you see this error, it probably means, that you did not bootstrap Web-UI correctly
        MissingConsumersStateError = Class.new(BaseError)

        # Similar to the above. It should be created during install
        MissingConsumersMetricsError = Class.new(BaseError)

        # This error occurs when consumer running older version of the web-ui tries to materialize
        # states from newer versions. Karafka Web-UI provides only backwards compatibility, so
        # you need to have an up-to-date consumer materializing reported states.
        #
        # If you see this error, please make sure that the consumer process that is materializing
        # your states is running at least the same version as the consumers that are reporting
        # the states
        #
        # If you see this error do not worry. When you get a consumer with up-to-date version,
        # all the historical metrics will catch up.
        IncompatibleSchemaError = Class.new(BaseError)
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
