# frozen_string_literal: true

RSpec.describe_current do
  subject(:pagination) { described_class.new }

  describe '#paginate?' do
    it 'raises NotImplementedError' do
      expect { pagination.paginate? }.to raise_error(NotImplementedError)
    end
  end

  describe '#first_offset?' do
    it 'raises NotImplementedError' do
      expect { pagination.first_offset? }.to raise_error(NotImplementedError)
    end
  end

  describe '#first_offset' do
    it 'raises NotImplementedError' do
      expect { pagination.first_offset }.to raise_error(NotImplementedError)
    end
  end

  describe '#previous_offset?' do
    it 'raises NotImplementedError' do
      expect { pagination.previous_offset? }.to raise_error(NotImplementedError)
    end
  end

  describe '#current_offset?' do
    it 'raises NotImplementedError' do
      expect { pagination.current_offset? }.to raise_error(NotImplementedError)
    end
  end

  describe '#next_offset?' do
    it 'raises NotImplementedError' do
      expect { pagination.next_offset? }.to raise_error(NotImplementedError)
    end
  end

  describe '#offset_key' do
    it 'raises NotImplementedError' do
      expect { pagination.offset_key }.to raise_error(NotImplementedError)
    end
  end
end
