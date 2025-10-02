# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:stop_command) { described_class.new({}) }

  before { allow(Process).to receive(:kill) }

  it 'expect to send a QUIT signal to the current process' do
    stop_command.call

    expect(Process).to have_received(:kill).with('QUIT', Process.pid)
  end

  context 'when process to which we send request is not a standalone one' do
    before { allow(Karafka::Server.execution_mode).to receive(:standalone?).and_return(false) }

    it 'expect to ignore quiet command in a swarm one' do
      stop_command.call

      expect(Process).not_to have_received(:kill)
    end
  end
end
