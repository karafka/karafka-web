# frozen_string_literal: true

require 'factory_bot'

coverage = !ENV.key?('GITHUB_WORKFLOW')
coverage = true if ENV['GITHUB_COVERAGE'] == 'true'

if coverage
  require 'simplecov'

  # Don't include unnecessary stuff into rcov
  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/vendor/'
    add_filter '/gems/'
    add_filter '/.bundle/'
    add_filter '/doc/'
    add_filter '/config/'

    merge_timeout 600
    minimum_coverage 0
    enable_coverage :branch
  end
end

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
  config.include FactoryBot::Syntax::Methods

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.before do
    ::Karafka::Web.config.tracking.producers.sampler.clear
  end
end

require 'karafka/core/helpers/rspec_locator'
RSpec.extend Karafka::Core::Helpers::RSpecLocator.new(__FILE__)

require 'karafka/web'

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

Karafka::Web.enable!

# @param topic_name [String] topic name. Default will generate automatically
# @param partitions [Integer] number of partitions (one by default)
# @return [String] generated topic name
def create_topic(topic_name = SecureRandom.uuid, partitions = 1)
  Karafka::Admin.create_topic(topic_name, partitions, 1)
  topic_name
end

# Sends data to Kafka in a sync way
# @param topic [String] topic name
# @param payload [String, nil] data we want to send
# @param details [Hash] other details
def produce(topic, payload = SecureRandom.uuid, details = {})
  Karafka::App.producer.produce_sync(
    **details.merge(
      topic: topic,
      payload: payload
    )
  )
end

# Sends multiple messages to kafka efficiently
# @param topic [String] topic name
# @param payloads [Array<String, nil>] data we want to send
# @param details [Hash] other details
def produce_many(topic, payloads, details = {})
  messages = payloads.map { |payload| details.merge(topic: topic, payload: payload) }

  Karafka::App.producer.produce_many_sync(messages)
end

# Fetches fixture content
# @param file_name [String] fixture file name
# @return [String] fixture content
def fixtures_file(file_name)
  File
    .dirname(__FILE__)
    .then { |location| File.join(location, 'fixtures', file_name) }
    .then { |fixture_path| File.read(fixture_path) }
end
