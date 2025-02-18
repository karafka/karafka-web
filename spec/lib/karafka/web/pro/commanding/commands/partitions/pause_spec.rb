# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:command) { described_class.new(command_request) }

  let(:command_request) { Karafka::Web::Pro::Commanding::Request.new(command_details) }
  let(:command_details) { { test: true } }
  let(:tracker) { Karafka::Web::Pro::Commanding::Handlers::Partitions::Tracker.instance }

  before do
    allow(Karafka::Web::Pro::Commanding::Handlers::Partitions::Tracker)
      .to receive(:instance)
      .and_return(tracker)

    allow(tracker).to receive(:<<)
    allow(command).to receive(:acceptance)
  end

  describe '#call' do
    it 'delegates the command to tracker and sends acceptance' do
      command.call

      expect(tracker).to have_received(:<<).with(command_request)
      expect(command).to have_received(:acceptance).with(command_details)
    end
  end
end
