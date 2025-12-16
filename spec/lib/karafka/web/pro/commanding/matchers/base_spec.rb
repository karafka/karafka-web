# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:matcher) { described_class.new(message) }

  let(:message) do
    instance_double(
      Karafka::Messages::Message,
      key: nil,
      payload: { schema_version: '1.2.0', matchers: {} },
      headers: { 'type' => 'request' }
    )
  end

  describe '#matches?' do
    it 'raises NotImplementedError' do
      expect { matcher.matches? }.to raise_error(NotImplementedError, 'Implement in a subclass')
    end
  end
end
