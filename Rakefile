# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"
require "minitest/test_task"

specs_type = ENV.fetch("SPECS_TYPE", "regular")

Minitest::TestTask.create(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_prelude = 'require "test_helper"; require "minitest/autorun"'

  t.test_globs = if specs_type == "pro"
    ["test/lib/karafka/web/pro/**/*_test.rb"]
  else
    # Exclude pro tests from regular test runs
    [
      "test/lib/karafka/web/*_test.rb",
      "test/lib/karafka/web/cli/**/*_test.rb",
      "test/lib/karafka/web/contracts/**/*_test.rb",
      "test/lib/karafka/web/management/**/*_test.rb",
      "test/lib/karafka/web/processing/**/*_test.rb",
      "test/lib/karafka/web/tracking/**/*_test.rb",
      "test/lib/karafka/web/ui/**/*_test.rb"
    ]
  end
end

task default: :test
