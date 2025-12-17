# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:base) { described_class.new(listener, client, request) }

  let(:listener) { instance_double(Karafka::Connection::Listener) }
  let(:client) { instance_double(Karafka::Connection::Client) }
  let(:request) { instance_double(Karafka::Web::Pro::Commanding::Request) }

  describe '#call' do
    it 'raises NotImplementedError' do
      expect { base.call }.to raise_error(NotImplementedError, 'Implement in a subclass')
    end
  end
end
