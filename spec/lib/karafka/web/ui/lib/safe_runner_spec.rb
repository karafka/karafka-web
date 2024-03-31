# frozen_string_literal: true

RSpec.describe_current do
  subject(:safe_runner) { described_class.new(&block) }

  describe '#call' do
    context 'when the block is successful' do
      let(:block) { -> { 'success' } }

      it 'returns the result of the block' do
        expect(safe_runner.call).to eq('success')
      end

      it 'sets success to true' do
        safe_runner.call
        expect(safe_runner.success?).to be true
      end
    end

    context 'when the block raises an error' do
      let(:block) { -> { raise StandardError, 'failure' } }

      it 'rescues the error and does not raise it' do
        expect { safe_runner.call }.not_to raise_error
      end

      it 'stores the error' do
        safe_runner.call
        expect(safe_runner.error).to be_a(StandardError)
        expect(safe_runner.error.message).to eq('failure')
      end

      it 'sets success to false' do
        safe_runner.call
        expect(safe_runner.success?).to be false
      end
    end
  end

  describe '#executed?' do
    context 'when before #call is invoked' do
      let(:block) { -> { 'not called' } }

      it 'returns false' do
        expect(safe_runner.executed?).to be false
      end
    end

    context 'when after #call is invoked' do
      let(:block) { -> { 'called' } }

      it 'returns true' do
        safe_runner.call
        expect(safe_runner.executed?).to be true
      end
    end
  end

  describe '#success?' do
    context 'when the block has not been executed yet' do
      let(:block) { -> { 'deferred success' } }

      it 'executes the block and returns true' do
        expect(safe_runner.success?).to be true
      end
    end
  end

  describe '#failure?' do
    context 'when the block raises an error' do
      let(:block) { -> { raise StandardError } }

      it 'executes the block and returns true for failure' do
        expect(safe_runner.failure?).to be true
      end
    end
  end
end
