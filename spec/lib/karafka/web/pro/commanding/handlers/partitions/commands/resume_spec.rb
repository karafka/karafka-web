# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:command) { described_class.new(listener, client, request) }

  let(:listener) { instance_double(Karafka::Connection::Listener) }
  let(:client) { instance_double(Karafka::Connection::Client) }

  let(:request) do
    Karafka::Web::Pro::Commanding::Request.new(
      reset_attempts: should_reset_attempts
    )
  end

  let(:coordinators) { instance_double(Karafka::Processing::CoordinatorsBuffer) }
  let(:coordinator) { instance_double(Karafka::Processing::Coordinator) }
  let(:pause_tracker) { instance_double(Karafka::TimeTrackers::Pause) }
  let(:topic) { 'topic_name' }
  let(:partition_id) { 1 }
  let(:should_reset_attempts) { false }

  before do
    allow(listener)
      .to receive(:coordinators)
      .and_return(coordinators)

    allow(coordinators)
      .to receive(:find_or_create)
      .with(topic, partition_id)
      .and_return(coordinator)

    allow(coordinator).to receive(:pause_tracker).and_return(pause_tracker)
    allow(pause_tracker).to receive(:expire)
    allow(pause_tracker).to receive(:reset)
    allow(command).to receive_messages(topic: topic, partition_id: partition_id, result: nil)
  end

  describe '#call' do
    context 'when reset_attempts is false' do
      let(:should_reset_attempts) { false }

      it 'expires the pause without resetting attempts' do
        command.call

        expect(pause_tracker).to have_received(:expire)
        expect(pause_tracker).not_to have_received(:reset)
        expect(command).to have_received(:result).with('applied')
      end
    end

    context 'when reset_attempts is true' do
      let(:should_reset_attempts) { true }

      it 'expires the pause and resets attempts' do
        command.call

        expect(pause_tracker).to have_received(:expire)
        expect(pause_tracker).to have_received(:reset)
        expect(command).to have_received(:result).with('applied')
      end
    end
  end
end
