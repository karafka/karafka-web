# frozen_string_literal: true

require "karafka/core/helpers/rspec_locator"

# Minitest locator that provides `describe_current` for auto-discovering the described class
# from the test file path, following the same pattern as RSpecLocator but for Minitest::Spec.
#
# Uses the same core locator logic from karafka-core to map file paths to class names.
class MinitestLocator < Karafka::Core::Helpers::RSpecLocator
  # Derives the class under test from the caller's file path
  # Searches the call stack for the first _test.rb file to handle any call depth
  # @return [Class] class for the Minitest `#describe` method
  def inherited
    test_file = caller.find { |frame| frame.include?("_test.rb") }

    raise "No _test.rb file found in call stack" unless test_file

    test_file
      .split(':')
      .first
      .gsub(@specs_root_dir, '')
      .gsub('_test.rb', '')
      .split('/')
      .delete_if(&:empty?)
      .itself[1..]
      .join('/')
      .then { |path| custom_camelize(path) }
      .then { |string| transform_inflections(string) }
      .then { |class_name| custom_constantize(class_name) }
  end

  # Builds needed API on the Minitest::Spec class
  # @param base [Class] Minitest::Spec class to extend
  def extended(base)
    this = self

    # Allows "auto subject" definitions for the `#describe` method, as it will figure
    # out the proper class that we want to describe
    # @param block [Proc] block with tests
    base.define_singleton_method :describe_current do |&block|
      full_name = this.inherited.to_s

      if full_name.include?("::Controllers") && full_name.end_with?("Controller")
        describe(this.inherited) do
          include Rack::Test::Methods
          include ControllerHelper

          instance_eval(&block)
        end
      else
        describe(this.inherited, &block)
      end
    end
  end
end
