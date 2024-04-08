# frozen_string_literal: true

RSpec.describe_current do
  subject(:stop_command) { described_class.new }

  before { allow(Process).to receive(:kill) }

  it 'expect to send a QUIT signal to the current process' do
    stop_command.call

    expect(Process).to have_received(:kill).with('QUIT', Process.pid)
  end
end
