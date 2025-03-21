# frozen_string_literal: true

RSpec.describe_current do
  subject(:metrics) { described_class }

  let(:metrics_topic) { create_topic }
  let(:fixture) { Fixtures.consumers_metrics_file }
  let(:fixture_hash) { Fixtures.consumers_metrics_json }

  before { Karafka::Web.config.topics.consumers.metrics.name = metrics_topic }

  context 'when no metrics' do
    it { expect(metrics.current).to be(false) }
    it { expect { metrics.current! }.to raise_error(::Karafka::Web::Errors::Ui::NotFoundError) }
  end

  context 'when one metric exists but karafka-web is not enabled' do
    let(:status) { Karafka::Web::Ui::Models::Status.new }

    before do
      allow(status.class).to receive(:new).and_return(status)
      allow(status).to receive(:enabled).and_return(OpenStruct.new(success?: false))
      produce(metrics_topic, Fixtures.consumers_metrics_file)
    end

    it { expect(metrics.current).to be(false) }
  end

  context 'when one metric exists and karafka-web is enabled' do
    before { produce(metrics_topic, fixture) }

    it 'expect to load data correctly' do
      expect(metrics.current).to be_a(described_class)
      expect(metrics.current.to_h).to eq(fixture_hash)
    end
  end

  context 'when there are more metrics and karafka-web is enabled' do
    let(:fixture1) { Fixtures.consumers_metrics_file }
    let(:fixture2) { Fixtures.consumers_metrics_file }
    let(:fixture_hash1) { Fixtures.consumers_metrics_json }
    let(:fixture_hash2) { Fixtures.consumers_metrics_json }

    before do
      fixture_hash2[:dispatched_at] = 1

      produce(metrics_topic, fixture_hash1.to_json)
      produce(metrics_topic, fixture_hash2.to_json)
    end

    it 'expect to load data correctly' do
      expect(metrics.current).to be_a(described_class)
      expect(metrics.current.dispatched_at).to eq(1)
      expect(metrics.current!.dispatched_at).to eq(1)
    end
  end
end
