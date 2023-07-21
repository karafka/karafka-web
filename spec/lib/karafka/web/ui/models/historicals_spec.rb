# frozen_string_literal: true

RSpec.describe_current do
  subject(:historicals) { described_class.new(state) }

  let(:dispatched_at) { Time.now.to_f.to_i }

  # Deep dup same way as we would get from Kafka
  let(:default_state) do
    state = Karafka::Web::Installer::DEFAULT_STATE.merge(dispatched_at: dispatched_at)
    Karafka::Web::Deserializer.new.call(OpenStruct.new(raw_payload: state.to_json))
  end

  context 'when stats are missing' do
    let(:state) { {} }

    it { expect { historicals }.to raise_error(KeyError) }
  end

  context 'when dispatched_at is missing' do
    let(:state) { { stats: {} } }

    it { expect { historicals }.to raise_error(KeyError) }
  end

  context 'when historicals are missing' do
    let(:state) { { stats: {}, dispatched_at: Time.now.to_f } }

    it { expect { historicals }.to raise_error(KeyError) }
  end

  context 'when historicals and stats are empty' do
    let(:state) { { stats: {}, dispatched_at: Time.now.to_f, historicals: {} } }

    it { expect { historicals }.to raise_error(KeyError) }
  end

  # This one makes sure we can work with the default empty bootstrapped state
  context 'when historicals and stats are present but without any values' do
    let(:state) { default_state }

    it { expect(historicals.days).to eq([]) }
    it { expect(historicals.hours).to eq([]) }
    it { expect(historicals.minutes).to eq([]) }
    it { expect(historicals.seconds).to eq([]) }
  end

  context 'when we had previous historicals in the same recent window' do
    pending
  end
end
