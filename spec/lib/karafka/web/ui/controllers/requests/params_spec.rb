# frozen_string_literal: true

RSpec.describe_current do
  let(:request_params) { { 'page' => '2', 'offset' => '10' } }

  subject(:params) { described_class.new(request_params) }

  describe '#current_page' do
    context 'when the page is a positive integer' do
      it 'returns the current page' do
        expect(params.current_page).to eq(2)
      end
    end

    context 'when the page is not a positive integer' do
      let(:request_params) { { 'page' => 'invalid' } }

      it 'returns 1' do
        expect(params.current_page).to eq(1)
      end
    end

    context 'when the page is not provided' do
      let(:request_params) { {} }

      it 'returns 1' do
        expect(params.current_page).to eq(1)
      end
    end
  end

  describe '#current_offset' do
    context 'when the offset is a valid integer' do
      it 'returns the current offset' do
        expect(params.current_offset).to eq(10)
      end
    end

    context 'when the offset is less than -1' do
      let(:request_params) { { 'offset' => '-10' } }

      it 'returns -1' do
        expect(params.current_offset).to eq(-1)
      end
    end

    context 'when the offset is not provided' do
      let(:request_params) { {} }

      it 'returns -1' do
        expect(params.current_offset).to eq(-1)
      end
    end
  end
end
