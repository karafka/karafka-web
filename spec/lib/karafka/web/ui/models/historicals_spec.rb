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

  context 'when we had no previous historicals but we do have current stats' do
    let(:state) do
      default_state.merge(
        stats: default_state[:stats].merge(messages: 10, batches: 2)
      )
    end

    it { expect(historicals.days).to eq([]) }
    it { expect(historicals.hours).to eq([]) }
    it { expect(historicals.minutes).to eq([]) }
    it { expect(historicals.seconds).to eq([]) }
  end

  context 'when we had historicals in the same recent window as current' do
    let(:state) do
      progress = default_state[:stats].merge(messages: 10, batches: 1)

      default_state.merge(
        stats: default_state[:stats].merge(messages: 23, batches: 2),
        historicals: {
          days: [[dispatched_at - 2, progress]],
          hours: [[dispatched_at - 2, progress]],
          minutes: [[dispatched_at - 2, progress]],
          seconds: [[dispatched_at - 2, progress]]
        }
      )
    end

    it { expect(historicals.days.size).to eq(1) }
    it { expect(historicals.hours.size).to eq(1) }
    it { expect(historicals.minutes.size).to eq(1) }
    it { expect(historicals.seconds.size).to eq(1) }
    it { expect(historicals.seconds.first.first).to eq(dispatched_at) }
    it { expect(historicals.seconds.first.last[:batch_size]).to eq(13) }
    it { expect(historicals.seconds.first.last[:batches]).to eq(1) }
  end

  context 'when we have short drifters in a historical window' do
    let(:state) do
      progress = default_state[:stats].merge(messages: 10, batches: 1, processes: 2, rss: 100)

      default_state.merge(
        stats: default_state[:stats].merge(messages: 23, batches: 2),
        historicals: {
          days: [
            [dispatched_at - 6_000, progress],
            [dispatched_at - 100, progress],
            [dispatched_at - 99, progress]
          ],
          hours: [
            [dispatched_at - 6_000, progress],
            [dispatched_at - 100, progress],
            [dispatched_at - 99, progress]
          ],
          minutes: [
            [dispatched_at - 6_000, progress],
            [dispatched_at - 100, progress],
            [dispatched_at - 99, progress]
          ],
          seconds: [
            [dispatched_at - 6_000, progress],
            [dispatched_at - 100, progress],
            [dispatched_at - 99, progress]
          ]
        }
      )
    end

    it { expect(historicals.days.size).to eq(3) }
    it { expect(historicals.hours.size).to eq(3) }
    it { expect(historicals.minutes.size).to eq(3) }
    it { expect(historicals.seconds.size).to eq(3) }
    it { expect(historicals.seconds.map(&:first)).not_to include(dispatched_at - 99) }
    it { expect(historicals.seconds.last.first).to eq(dispatched_at) }
    it { expect(historicals.seconds.first.last[:batch_size]).to eq(0) }
    it { expect(historicals.seconds.first.last[:batches]).to eq(0) }
    it { expect(historicals.seconds.first.last[:process_rss]).to eq(50) }
  end

  context 'when we have long drifters in a historical window' do
    let(:state) do
      progress = default_state[:stats].merge(messages: 10, batches: 1, processes: 2, rss: 100)

      default_state.merge(
        stats: default_state[:stats].merge(messages: 23, batches: 2),
        historicals: {
          days: [
            [dispatched_at - 6_000, progress],
            [dispatched_at - 100, progress],
            [dispatched_at - 91, progress]
          ],
          hours: [
            [dispatched_at - 6_000, progress],
            [dispatched_at - 100, progress],
            [dispatched_at - 91, progress]
          ],
          minutes: [
            [dispatched_at - 6_000, progress],
            [dispatched_at - 100, progress],
            [dispatched_at - 91, progress]
          ],
          seconds: [
            [dispatched_at - 6_000, progress],
            [dispatched_at - 100, progress],
            [dispatched_at - 91, progress]
          ]
        }
      )
    end

    it { expect(historicals.days.size).to eq(3) }
    it { expect(historicals.hours.size).to eq(3) }
    it { expect(historicals.minutes.size).to eq(3) }
    it { expect(historicals.seconds.size).to eq(5) }
    it { expect(historicals.seconds.map(&:first)).not_to include(dispatched_at - 6_000) }
    it { expect(historicals.seconds.map(&:first)).to include(dispatched_at - 91) }
    it { expect(historicals.seconds.map(&:first)).to include(dispatched_at - 96) }
    it { expect(historicals.seconds.last.first).to eq(dispatched_at) }
    it { expect(historicals.seconds.first.last[:batch_size]).to eq(0) }
    it { expect(historicals.seconds.first.last[:batches]).to eq(0) }
    it { expect(historicals.seconds.first.last[:process_rss]).to eq(50) }
  end

  context 'when we have do not have long drifters in a historical window' do
    let(:state) do
      progress = default_state[:stats].merge(messages: 10, batches: 1, processes: 2, rss: 100)

      default_state.merge(
        stats: default_state[:stats].merge(messages: 23, batches: 2),
        historicals: {
          days: [
            [dispatched_at - 6_000, progress],
            [dispatched_at - 100, progress],
            [dispatched_at - 95, progress]
          ],
          hours: [
            [dispatched_at - 6_000, progress],
            [dispatched_at - 100, progress],
            [dispatched_at - 95, progress]
          ],
          minutes: [
            [dispatched_at - 6_000, progress],
            [dispatched_at - 100, progress],
            [dispatched_at - 95, progress]
          ],
          seconds: [
            [dispatched_at - 6_000, progress],
            [dispatched_at - 100, progress],
            [dispatched_at - 95, progress]
          ]
        }
      )
    end

    it { expect(historicals.days.size).to eq(3) }
    it { expect(historicals.hours.size).to eq(3) }
    it { expect(historicals.minutes.size).to eq(3) }
    it { expect(historicals.seconds.size).to eq(4) }
    it { expect(historicals.seconds.map(&:first)).not_to include(dispatched_at - 6_000) }
    it { expect(historicals.seconds.map(&:first)).to include(dispatched_at - 95) }
    it { expect(historicals.seconds.last.first).to eq(dispatched_at) }
    it { expect(historicals.seconds.first.last[:batch_size]).to eq(0) }
    it { expect(historicals.seconds.first.last[:batches]).to eq(0) }
    it { expect(historicals.seconds.first.last[:process_rss]).to eq(50) }
  end
end
