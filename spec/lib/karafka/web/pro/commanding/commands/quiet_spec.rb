# frozen_string_literal: true

RSpec.describe_current do
  subject(:quiet_command) { described_class.new }

  before { allow(Process).to receive(:kill) }

  it 'expect to send a TSTP signal to the current process' do
    quiet_command.call

    expect(Process).to have_received(:kill).with('TSTP', Process.pid)
  end
end
