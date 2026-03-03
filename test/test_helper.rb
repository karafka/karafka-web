# frozen_string_literal: true

require "simplecov"
require "rack/test"
require "ostruct"
require "nokogiri"
require "singleton"

# Are we running regular tests or pro tests
SPECS_TYPE = ENV.fetch("SPECS_TYPE", "default")

# Parallel group ID for unique SimpleCov command names
PARALLEL_GROUP_ID = ENV.fetch("PARALLEL_GROUP_ID", "")

# Don't include unnecessary stuff into rcov
SimpleCov.start do
  add_filter "/test/"
  add_filter "/vendor/"
  add_filter "/gems/"
  add_filter "/.bundle/"
  add_filter "/doc/"
  add_filter "/config/"

  # Use unique command name per parallel group for proper merging
  cmd_name = PARALLEL_GROUP_ID.empty? ? SPECS_TYPE : "#{SPECS_TYPE}-#{PARALLEL_GROUP_ID}"
  command_name cmd_name
  merge_timeout 3600
  enable_coverage :branch
end

# Only check minimum coverage when not running in parallel mode
# Coverage is checked after merging all results in bin/check_coverage
if SPECS_TYPE == "pro" && ENV["PARALLEL"].nil?
  require_relative "support/coverage_config"
  SimpleCov.minimum_coverage(
    line: CoverageConfig::LINE_COVERAGE,
    branch: CoverageConfig::BRANCH_COVERAGE
  )
end

# Load Pro components when running pro specs
if ENV["SPECS_TYPE"] == "pro"
  mod = Module.new do
    def self.token
      ENV.fetch("KARAFKA_PRO_LICENSE_TOKEN")
    end
  end

  Karafka.const_set(:License, mod)
  require "zeitwerk"
  require "karafka/pro/loader"
end

require "karafka/web"

require "minitest/autorun"
require "minitest/spec"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Provide described_class support in Minitest::Spec
# Walks the describe hierarchy to find the class being described
module MinitestDescribedClass
  def described_class
    klass = self.class

    while klass&.respond_to?(:desc)
      return klass.desc if klass.desc.is_a?(Class) || klass.desc.is_a?(Module)

      klass = klass.superclass
    end

    nil
  end
end

# Relax Minitest::Spec let restrictions for RSpec migrated tests
# Allows let(:message) etc. which RSpec permitted but Minitest blocks
# Still protects critical Minitest internals like :run that would break test execution
# When overriding internal methods (e.g. :message), the method is dispatched by arity:
# called with no args returns the memoized let value, with args delegates to the original
MINITEST_CRITICAL_METHODS = %w[run setup teardown].freeze

Minitest::Spec::DSL.class_eval do
  def let(name, &block)
    name = name.to_s
    pre, post = "let '#{name}' cannot ", ". Please use another name."

    raise ArgumentError, "#{pre}override a critical Minitest method#{post}" if
      MINITEST_CRITICAL_METHODS.include?(name)

    original = begin
      instance_method(name)
    rescue NameError
      nil
    end

    if original
      define_method(name) do |*args, **kwargs, &blk|
        if args.empty? && kwargs.empty? && blk.nil?
          @_memoized ||= {}
          @_memoized.fetch(name) { |k| @_memoized[k] = instance_eval(&block) }
        else
          original.bind_call(self, *args, **kwargs, &blk)
        end
      end
    else
      define_method(name) do
        @_memoized ||= {}
        @_memoized.fetch(name) { |k| @_memoized[k] = instance_eval(&block) }
      end
    end
  end
end

# Add context as alias for describe, and include helpers
class Minitest::Spec
  include MinitestDescribedClass
  include Factories
  include TopicsManagerHelper
  include MockCompat
  include MockExpectIntegration

  class << self
    alias_method :context, :describe
  end
end

# Extend Minitest::Spec with the locator for describe_current
Minitest::Spec.extend MinitestLocator.new(__FILE__)

# Make describe_current available at top level (like Minitest's describe via Kernel)
module Kernel
  private

  def describe_current(&block)
    Minitest::Spec.describe_current(&block)
  end
end

include TopicsManagerHelper

# We set it here because we fake Web-UI topics and without this the faked once would have
# the default deserializer instead of the Web one. Since we reset routes with each test and
# dynamically "replace" certain web ui topics in particular tests, we need to have the web
# deserializer set always for each test to simplify things. Otherwise we would have to re-draw
# defaults in each test after any of the web-ui topics alterations.
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
      config.kafka = { "bootstrap.servers": "127.0.0.1:9092" }
      config.client_id = rand.to_s
    end
  end
end

# Alias for two producers that we need in tests. Regular one that is not transactional and the
# other one that is transactional for transactional tests
PRODUCERS = Struct.new(:regular, :transactional).new(
  Karafka.producer,
  WaterDrop::Producer.new do |p_config|
    p_config.kafka = Karafka::Setup::AttributesMap.producer(Karafka::App.config.kafka.dup)
    p_config.kafka[:"transactional.id"] = SecureRandom.uuid
    p_config.logger = Karafka::App.config.logger
  end
)

# Topics that we will use for all the tests as the primary karafka-web topics for valid cases
TOPICS = Array.new(5) { create_topic }

# Global setup that runs before each test
Minitest::Spec.class_eval do
  before do
    # Prepare clean routing setup for each test
    # We do this because some of the tests extend routing and we do not want them to interfere
    # with each other.
    Karafka::App.routes.clear
    draw_defaults
    Karafka::Web::Management::Actions::Enable.new.send(:extend_routing)

    Karafka::Web.config.tracking.consumers.sampler.clear
    Karafka::Web.config.tracking.producers.sampler.clear
    Karafka::Web.config.ui.cache.clear

    # Set existing topics
    Karafka::Web.config.topics.consumers.states.name = TOPICS[0]
    Karafka::Web.config.topics.consumers.metrics.name = TOPICS[1]
    Karafka::Web.config.topics.consumers.reports.name = TOPICS[2]
    Karafka::Web.config.topics.consumers.commands.name = TOPICS[3]
    Karafka::Web.config.topics.errors.name = TOPICS[4]

    # Enable all features in case they were disabled for the controllers tests
    if Karafka.pro? && described_class &&
        described_class < Karafka::Web::Ui::Controllers::BaseController
      Karafka::Web.config.commanding.active = true
      Karafka::Web.config.ui.topics.management.active = true
    end
  end

  # Restore them as some tests modify those
  after do
    MockCompat.cleanup!

    Karafka::Web.config.topics.consumers.states.name = TOPICS[0]
    Karafka::Web.config.topics.consumers.metrics.name = TOPICS[1]
    Karafka::Web.config.topics.consumers.reports.name = TOPICS[2]
    Karafka::Web.config.topics.consumers.commands.name = TOPICS[3]
    Karafka::Web.config.topics.errors.name = TOPICS[4]
  end

  # Links validation for controller tests
  after do
    # Skip if this is not a controller test (no Rack::Test methods)
    next unless respond_to?(:last_response)
    # Do not proceed if there were any errors in the test
    next if failures.any?
    # Analyze only valid html responses data
    next unless response&.content_type&.include?("text/html")

    validator = LinksValidator.instance
    validator.context = self
    validator.description = name
    validator.validate_all!(response)
  end
end

Minitest.after_run do
  PRODUCERS.regular.close
  PRODUCERS.transactional.close
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
produce(TOPICS[3], Fixtures.consumers_commands_file("consumers/current.json"))

# Run the migrations so even if we use older fixtures, the data in Kafka is aligned
Karafka::Web::Management::Actions::MigrateStatesData.new.call

Karafka::Web.enable!

# Disable CSRF checks for tests
# Must configure on all classes due to Roda's opts inheritance
Karafka::Web::Ui::Base.plugin(:sec_fetch_site_csrf, check_request_methods: [])
Karafka::Web::Ui::App.plugin(:sec_fetch_site_csrf, check_request_methods: [])
Karafka::Web::Pro::Ui::App.plugin(:sec_fetch_site_csrf, check_request_methods: []) if Karafka.pro?

# We need to clear argv because otherwise we would get reports on invalid options for CLI tests
ARGV.clear

# Temporary patch until the new Karafka version is released
unless Karafka::Connection::Listener.method_defined?(:coordinators)
  Karafka::Connection::Listener.class_eval do
    def coordinators
    end
  end
end
