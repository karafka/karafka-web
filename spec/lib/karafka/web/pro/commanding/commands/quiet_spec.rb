# frozen_string_literal: true

RSpec.describe_current do
  subject(:quiet_command) { described_class.new }

  before { allow(Process).to receive(:kill) }

  it 'expect to send a TSTP signal to the current process' do
    quiet_command.call

    expect(Process).to have_received(:kill).with('TSTP', Process.pid)
  end

  context 'when process to which we send request is an embedded one' do
    before { allow(Karafka::Server).to receive(:execution_mode).and_return(:embedded) }

    it 'expect to ignore quiet command in an embedded one' do
      quiet_command.call

      expect(Process).not_to have_received(:kill)
    end
  end

  context 'when process to which we send request is a swarm one' do
    before { allow(Karafka::Server).to receive(:execution_mode).and_return(:swarm) }

    it 'expect to ignore quiet command in a swarm one' do
      quiet_command.call

      expect(Process).not_to have_received(:kill)
    end
  end
end
