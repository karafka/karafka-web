# frozen_string_literal: true

describe_current do
  let(:oss_injector) { Karafka::Web::Config::DefaultsInjector }
  let(:ui_kafka) { Karafka::Web.config.ui.kafka }

  it "expect to be prepended onto the OSS Web injector when Pro is enabled" do
    assert_includes oss_injector.singleton_class.ancestors, described_class
  end

  it "expect the OSS injector to still expose the Web UI kafka defaults through the overlay" do
    ui_kafka.each do |key, value|
      assert_equal value, oss_injector.defaults[key]
    end
  end

  describe "layering" do
    subject(:injector) do
      base = { "fetch.wait.max.ms": 100, a: 1 }

      Class.new(Karafka::Core::Configurable::Injector) do
        define_singleton_method(:defaults) { base }
      end
    end

    before { injector.singleton_class.prepend(described_class) }

    it "expect to keep the base (super) defaults" do
      assert_equal 100, injector.defaults[:"fetch.wait.max.ms"]
      assert_equal 1, injector.defaults[:a]
    end

    it "expect to merge the Pro defaults on top of the base" do
      described_class::KAFKA_DEFAULTS.each do |key, value|
        assert_equal value, injector.defaults[key]
      end
    end

    it "expect not to mutate the base defaults when merging" do
      injector.defaults

      refute_same injector.defaults, described_class::KAFKA_DEFAULTS
    end
  end
end
