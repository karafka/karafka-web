# frozen_string_literal: true

RSpec.describe_current do
  subject(:state) { described_class }

  let(:states_topic) { create_topic }
  let(:fixture) { Fixtures.consumers_states_file }
  let(:fixture_hash) { Fixtures.consumers_states_json }

  before { Karafka::Web.config.topics.consumers.states.name = states_topic }

  context 'when no state' do
    it { expect(state.current).to be(false) }
    it { expect { state.current! }.to raise_error(::Karafka::Web::Errors::Ui::NotFoundError) }
  end

  context 'when one state exists but karafka-web is not enabled' do
    let(:status) { Karafka::Web::Ui::Models::Status.new }

    before do
      allow(status.class).to receive(:new).and_return(status)
      allow(status).to receive(:enabled).and_return(OpenStruct.new(success?: false))
      produce(states_topic, Fixtures.consumers_states_file)
    end

    it { expect(state.current).to be(false) }
  end

  context 'when one state exists and karafka-web is enabled' do
    before { produce(states_topic, fixture) }

    it 'expect to load data correctly' do
      expect(state.current).to be_a(described_class)
      expect(state.current.to_h).to eq(fixture_hash)
    end
  end

  context 'when there are more states and karafka-web is enabled' do
    let(:fixture1) { Fixtures.consumers_states_file }
    let(:fixture2) { Fixtures.consumers_states_file }
    let(:fixture_hash1) { Fixtures.consumers_states_json }
    let(:fixture_hash2) { Fixtures.consumers_states_json }

    before do
      fixture_hash2[:dispatched_at] = 1

      produce(states_topic, fixture_hash1.to_json)
      produce(states_topic, fixture_hash2.to_json)
    end

    it 'expect to load data correctly' do
      expect(state.current).to be_a(described_class)
      expect(state.current.dispatched_at).to eq(1)
      expect(state.current!.dispatched_at).to eq(1)
    end
  end

  context 'when our state contains only old processes data' do
    before do
      fixture_hash[:processes][:'shinra:1:1'][:dispatched_at] = Time.now.to_f - 60
      fixture_hash[:processes][:'shinra:2:2'][:dispatched_at] = Time.now.to_f - 31
      produce(states_topic, fixture_hash.to_json)
    end

    it 'expect to load data correctly' do
      expect(state.current).to be_a(described_class)
      expect(state.current.processes).to be_empty
    end
  end

  context 'when our state contains old and new processes data' do
    before do
      fixture_hash[:processes][:'shinra:1:1'][:dispatched_at] = Time.now.to_f - 60
      fixture_hash[:processes][:'shinra:2:2'][:dispatched_at] = Time.now.to_f - 1
      produce(states_topic, fixture_hash.to_json)
    end

    it 'expect to load data correctly' do
      expect(state.current).to be_a(described_class)
      expect(state.current.processes.size).to eq(1)
      expect(state.current.processes.keys).to include(:'shinra:2:2')
    end
  end

  context 'when our state contains data about processes in non-asc order' do
    before do
      fixture_hash[:processes][:'a:1:1'] = fixture_hash[:processes][:'shinra:1:1'].dup
      produce(states_topic, fixture_hash.to_json)
    end

    it 'expect to sort it' do
      values = state.current.processes.keys.map(&:to_s)
      expect(values).to eq(values.sort)
    end
  end
end
