# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:matcher) { described_class.new('test_value') }

  describe '#matches?' do
    it 'raises NotImplementedError' do
      expect { matcher.matches? }.to raise_error(NotImplementedError, 'Implement in a subclass')
    end
  end
end
