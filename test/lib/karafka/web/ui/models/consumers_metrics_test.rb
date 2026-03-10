# frozen_string_literal: true

describe_current do
  let(:metrics) { described_class }

  let(:metrics_topic) { create_topic }
  let(:fixture) { Fixtures.consumers_metrics_file }
  let(:fixture_hash) { Fixtures.consumers_metrics_json }

  before { Karafka::Web.config.topics.consumers.metrics.name = metrics_topic }

  context "when no metrics" do
    it { refute(metrics.current) }
    it { assert_raises(Karafka::Web::Errors::Ui::NotFoundError) { metrics.current! } }
  end

  context "when one metric exists but karafka-web is not enabled" do
    let(:status) { Karafka::Web::Ui::Models::Status.new }

    before do
      status.class.stubs(:new).returns(status)
      status.stubs(:enabled).returns(Struct.new(:success?).new(false))
      produce(metrics_topic, Fixtures.consumers_metrics_file)
    end

    it { refute(metrics.current) }
  end

  context "when one metric exists and karafka-web is enabled" do
    before { produce(metrics_topic, fixture) }

    it "expect to load data correctly" do
      assert_kind_of(described_class, metrics.current)
      assert_equal(fixture_hash, metrics.current.to_h)
    end
  end

  context "when there are more metrics and karafka-web is enabled" do
    let(:fixture1) { Fixtures.consumers_metrics_file }
    let(:fixture2) { Fixtures.consumers_metrics_file }
    let(:fixture_hash1) { Fixtures.consumers_metrics_json }
    let(:fixture_hash2) { Fixtures.consumers_metrics_json }

    before do
      fixture_hash2[:dispatched_at] = 1

      produce(metrics_topic, fixture_hash1.to_json)
      produce(metrics_topic, fixture_hash2.to_json)
    end

    it "expect to load data correctly" do
      assert_kind_of(described_class, metrics.current)
      assert_equal(1, metrics.current.dispatched_at)
      assert_equal(1, metrics.current!.dispatched_at)
    end
  end
end
