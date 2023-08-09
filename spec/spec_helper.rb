# frozen_string_literal: true

require 'factory_bot'
require 'simplecov'
require 'rack/test'

# Don't include unnecessary stuff into rcov
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
  add_filter '/gems/'
  add_filter '/.bundle/'
  add_filter '/doc/'
  add_filter '/config/'

  merge_timeout 600
  minimum_coverage 85
  enable_coverage :branch
end

require 'karafka/web'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
  config.include FactoryBot::Syntax::Methods
  config.include Rack::Test::Methods, type: :controller
  config.include ControllerHelper, type: :controller

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.before do
    ::Karafka::Web.config.tracking.consumers.sampler.clear
    ::Karafka::Web.config.tracking.producers.sampler.clear
  end

  # Restore them as some specs modify those
  config.after do
    ::Karafka::Web.config.topics.consumers.states = TOPICS[0]
    ::Karafka::Web.config.topics.consumers.metrics = TOPICS[1]
    ::Karafka::Web.config.topics.consumers.reports = TOPICS[2]
    ::Karafka::Web.config.topics.errors = TOPICS[3]
  end
end

RSpec.extend RSpecLocator.new(__FILE__)
include TopicsManagerHelper

# Fetches fixture content
# @param file_name [String] fixture file name
# @return [String] fixture content
def fixtures_file(file_name)
  File
    .dirname(__FILE__)
    .then { |location| File.join(location, 'fixtures', file_name) }
    .then { |fixture_path| File.read(fixture_path) }
end

module Karafka
  # Configuration for test env
  class App
    setup do |config|
      config.kafka = { 'bootstrap.servers': '127.0.0.1:9092' }
      config.client_id = rand.to_s
      # We set it here because we fake Web-UI topics and without this the faked once would have
      # the default deserializer instead of the Web one
      config.deserializer = Karafka::Web::Deserializer.new
    end
  end
end

# Topics that we will use for all the tests as the primary karafka-web topics for valid cases
TOPICS = Array.new(4) { create_topic }

RSpec.configure do |config|
  # Set existing topics
  config.before do
    ::Karafka::Web.config.topics.consumers.states = TOPICS[0]
    ::Karafka::Web.config.topics.consumers.metrics = TOPICS[1]
    ::Karafka::Web.config.topics.consumers.reports = TOPICS[2]
    ::Karafka::Web.config.topics.errors = TOPICS[3]
  end
end

Karafka::Web.setup do |config|
  config.topics.consumers.states = TOPICS[0]
  config.topics.consumers.metrics = TOPICS[1]
  config.topics.consumers.reports = TOPICS[2]
  config.topics.errors = TOPICS[3]
end

produce(TOPICS[0], fixtures_file('consumers_state.json'))
produce(TOPICS[1], fixtures_file('consumers_metrics.json'))
produce(TOPICS[2], fixtures_file('consumer_report.json'))

Karafka::Web.enable!
