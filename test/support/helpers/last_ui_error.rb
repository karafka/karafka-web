# frozen_string_literal: true

# Captures every Web UI unhandled error instrumented during a test (dispatched via the same
# `error.occurred` monitor event the production error handler already uses), so `assert_ok`
# (see `ControllerHelper`) can surface the actual exception(s) on a 500 instead of just a
# generic HTML body dump. This has been the main blocker in diagnosing rare CI-only flakes in
# the Explorer controller specs, where the failure only ever showed the static error page body.
#
# @note We keep all errors captured during a test, not just the last one, in case more than one
#   occurs (e.g. a request that triggers an error and a subsequent teardown/link-validation pass
#   that trips on the resulting page).
module LastUiError
  class << self
    attr_accessor :errors

    def clear
      self.errors = []
    end
  end

  clear
end
