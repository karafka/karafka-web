# frozen_string_literal: true

require 'karafka/core/helpers/rspec_locator'

# We need a slightly special locator because of Pro
class RSpecLocator < ::Karafka::Core::Helpers::RSpecLocator
  # Builds needed API
  # @param rspec [Module] RSpec main module
  def extended(rspec)
    super

    this = self

    # Allows "auto subject" definitions for the `#describe` method, as it will figure
    # out the proper class that we want to describe
    # @param block [Proc] block with specs
    rspec.define_singleton_method :describe_current do |&block|
      full_name = this.inherited.to_s

      if full_name.include?('::Controllers') && full_name.end_with?('Controller')
        describe(this.inherited, type: :controller, &block)
      else
        describe(this.inherited, type: :regular, &block)
      end
    end
  end
end
