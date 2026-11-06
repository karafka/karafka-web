# frozen_string_literal: true

source "https://rubygems.org"

# Needed until karafka 2.6.2 release (Karafka::Admin.delete_records)
gem "karafka", git: "https://github.com/karafka/karafka", branch: "master"

gemspec

gem "rake"

group :test do
  gem "fugit"
  gem "mocha"
  gem "ostruct"
  gem "rack-test"
  gem "minitest"
  gem "simplecov"
  gem "warning"
end
