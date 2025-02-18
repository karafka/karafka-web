# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:request) { described_class.new(details) }

  let(:details) do
    {
      name: command_name,
      additional: 'value'
    }
  end

  let(:command_name) { 'test_command' }

  describe '#name' do
    it 'returns the command name from details' do
      expect(request.name).to eq(command_name)
    end

    context 'when name is missing from details' do
      let(:details) { {} }

      it 'raises KeyError' do
        expect { request.name }.to raise_error(KeyError)
      end
    end
  end

  describe '#[]' do
    context 'when key exists' do
      it 'returns the value for given key' do
        expect(request[:additional]).to eq('value')
      end
    end

    context 'when key does not exist' do
      it 'raises KeyError' do
        expect { request[:non_existent] }.to raise_error(KeyError)
      end
    end
  end

  describe '#to_h' do
    it 'returns the original details hash' do
      expect(request.to_h).to eq(details)
    end

    it 'returns the same object that was passed to initialize' do
      expect(request.to_h).to be(details)
    end
  end

  describe '#initialize' do
    context 'when initialized with empty hash' do
      let(:details) { {} }

      it 'creates instance without errors' do
        expect { request }.not_to raise_error
      end
    end

    context 'when initialized with nil' do
      let(:details) { nil }

      it 'raises NoMethodError' do
        expect { request[:anything] }.to raise_error(NoMethodError)
      end
    end
  end
end
