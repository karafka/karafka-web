# frozen_string_literal: true

source 'https://rubygems.org'

plugin 'diffend'

gemspec

# Remove prior to new Web UI release
gem 'karafka', github: 'karafka/karafka'

group :test do
  gem 'byebug'
  gem 'factory_bot'
  gem 'fugit'
  # Needed for links extraction for visits verification
  gem 'nokogiri'
  gem 'ostruct'
  gem 'rack-test'
  gem 'rspec'
  gem 'simplecov'
end
