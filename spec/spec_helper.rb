# frozen_string_literal: true

require 'factory_bot'
require 'simplecov'
require 'rack/test'
require 'ostruct'
require 'nokogiri'
require 'singleton'

# Are we running regular specs or pro specs
SPECS_TYPE = ENV.fetch('SPECS_TYPE', 'default')

# Don't include unnecessary stuff into rcov
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
  add_filter '/gems/'
  add_filter '/.bundle/'
  add_filter '/doc/'
  add_filter '/config/'

  command_name SPECS_TYPE
  merge_timeout 3600
  enable_coverage :branch
end

SimpleCov.minimum_coverage(92) if SPECS_TYPE == 'pro'

# Load Pro components when running pro specs
if ENV['SPECS_TYPE'] == 'pro'
  mod = Module.new do
    def self.token
      ENV.fetch('KARAFKA_PRO_LICENSE_TOKEN')
    end
  end

  Karafka.const_set(:License, mod)
  require 'zeitwerk'
  require 'karafka/pro/loader'
end

require 'karafka/web'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
  config.include FactoryBot::Syntax::Methods
  config.include Rack::Test::Methods, type: :controller
  config.include ControllerHelper, type: :controller

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Prevents you from stubbing a method that does not exist on a real object
    mocks.verify_partial_doubles = true
  end

  config.before do
    # Prepare clean routing setup for each spec
    # We do this because some of the specs extend routing and we do not want them to interfere
    # with each other.
    Karafka::App.routes.clear
    draw_defaults
    Karafka::Web::Management::Actions::Enable.new.send(:extend_routing)

    Karafka::Web.config.tracking.consumers.sampler.clear
    Karafka::Web.config.tracking.producers.sampler.clear
    Karafka::Web.config.ui.cache.clear

    # Enable all features in case they were disabled for the controllers specs

    if Karafka.pro? && described_class < Karafka::Web::Ui::Controllers::BaseController
      Karafka::Web.config.commanding.active = true
      Karafka::Web.config.ui.topics.management.active = true
    end
  end

  # Restore them as some specs modify those
  config.after do
    Karafka::Web.config.topics.consumers.states.name = TOPICS[0]
    Karafka::Web.config.topics.consumers.metrics.name = TOPICS[1]
    Karafka::Web.config.topics.consumers.reports.name = TOPICS[2]
    Karafka::Web.config.topics.consumers.commands.name = TOPICS[3]
    Karafka::Web.config.topics.errors.name = TOPICS[4]
  end

  config.after(:suite) do
    PRODUCERS.regular.close
    PRODUCERS.transactional.close
  end

  config.after(:each, type: :controller) do |example|
    # Do not proceed if there were any errors in the test
    next if example.exception
    # Analyze only valid html responses data
    next unless response&.content_type&.include?('text/html')

    validator = LinksValidator.instance
    validator.context = self
    validator.validate_all!(response)
  end
end

RSpec.extend RSpecLocator.new(__FILE__)
include TopicsManagerHelper

# We set it here because we fake Web-UI topics and without this the faked once would have
# the default deserializer instead of the Web one. Since we reset routes with each spec and
# dynamically "replace" certain web ui topics in particular specs, we need to have the web
# deserializer set always for each spec to simplify things. Otherwise we would have to re-draw
# defaults in each spec after any of the web-ui topics alterations.
def draw_defaults
  Karafka::App.routes.draw do
    defaults do
      deserializers(
        payload: Karafka::Web::Deserializer.new
      )
    end
  end
end

module Karafka
  # Configuration for test env
  class App
    setup do |config|
      config.kafka = { 'bootstrap.servers': '127.0.0.1:9092' }
      config.client_id = rand.to_s
    end
  end
end

# Alias for two producers that we need in specs. Regular one that is not transactional and the
# other one that is transactional for transactional specs
PRODUCERS = Struct.new(:regular, :transactional).new(
  Karafka.producer,
  WaterDrop::Producer.new do |p_config|
    p_config.kafka = Karafka::Setup::AttributesMap.producer(Karafka::App.config.kafka.dup)
    p_config.kafka[:'transactional.id'] = SecureRandom.uuid
    p_config.logger = Karafka::App.config.logger
  end
)

# Topics that we will use for all the tests as the primary karafka-web topics for valid cases
TOPICS = Array.new(5) { create_topic }

RSpec.configure do |config|
  # Set existing topics
  config.before do
    Karafka::Web.config.topics.consumers.states.name = TOPICS[0]
    Karafka::Web.config.topics.consumers.metrics.name = TOPICS[1]
    Karafka::Web.config.topics.consumers.reports.name = TOPICS[2]
    Karafka::Web.config.topics.consumers.commands.name = TOPICS[3]
    Karafka::Web.config.topics.errors.name = TOPICS[4]
  end
end

Karafka::Web.setup do |config|
  config.topics.consumers.states.name = TOPICS[0]
  config.topics.consumers.metrics.name = TOPICS[1]
  config.topics.consumers.reports.name = TOPICS[2]
  config.topics.consumers.commands.name = TOPICS[3]
  config.topics.errors.name = TOPICS[4]

  # Disable so it is not auto-subscribed under the hood of tests
  config.commanding.active = false if Karafka.pro?
end

draw_defaults

produce(TOPICS[0], Fixtures.consumers_states_file)
produce(TOPICS[1], Fixtures.consumers_metrics_file)
produce(TOPICS[2], Fixtures.consumers_reports_file)
produce(TOPICS[3], Fixtures.consumers_commands_file('consumers/current.json'))

# Run the migrations so even if we use older fixtures, the data in Kafka is aligned
Karafka::Web::Management::Actions::MigrateStatesData.new.call

Karafka::Web.enable!

# Disable CSRF checks for RSpec
Karafka::Web::App.engine.plugin(:route_csrf, check_request_methods: [])

# We need to clear argv because otherwise we would get reports on invalid options for CLI specs
ARGV.clear

# Temporary patch until the new Karafka version is released
unless Karafka::Connection::Listener.method_defined?(:coordinators)
  Karafka::Connection::Listener.class_eval do
    def coordinators; end
  end
end
