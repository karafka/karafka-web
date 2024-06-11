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

      # Raised when you try to configure Web UI but Karafka was not yet configured and is not in
      # a state to accept Web UI integration.
      #
      # If you are seeing this error, it means you tried to configure and setup the Web UI before
      # you configured Karafka. In case of a "split-setup" where you divided your `karafka.rb`
      # into separate files, likely you are requiring the web-ui component prior to the one that
      # configures Karafka
      KarafkaNotInitializedError = Class.new(BaseError)

      # Errors specific to management
      module Management
        # Similar to processing error with the same name, it is raised when a critical
        # incompatibility is detected.
        #
        # This error is raised when there was an attempt to operate on aggregated Web UI states
        # that are already in a newer version that the one in the current process. We prevent
        # this from happening not to corrupt the data. Please upgrade all the Web UI consumers to
        # the same version
        IncompatibleSchemaError = Class.new(BaseError)
      end

      # Processing related errors namespace
      module Processing
        # Raised when we try to process reports but we do not have the current state bootstrapped
        # If you see this error, it probably means, that you did not bootstrap Web-UI correctly
        MissingConsumersStateError = Class.new(BaseError)

        # Raised when we try to materialize the state but the consumers states topic does not
        # exist and we do not have a way to get the initial state.
        # It differs from the above because above indicates that the topic exists but that there
        # is no initial state, while this indicates, that there is no consumers states topic.
        MissingConsumersStatesTopicError = Class.new(BaseError)

        # Similar to the above. It should be created during install / migration
        MissingConsumersMetricsError = Class.new(BaseError)

        # Similar to the one related to consumers states
        MissingConsumersMetricsTopicError = Class.new(BaseError)

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

        # Raised when we want to stop the flow and render 403
        ForbiddenError = Class.new(BaseError)
      end
    end
  end
end
