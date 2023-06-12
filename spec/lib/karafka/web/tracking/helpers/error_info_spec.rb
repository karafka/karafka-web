# frozen_string_literal: true

RSpec.describe_current do
  subject(:extractor) do
    helper = described_class

    Class
      .new { include(helper) }
      .new
  end

  let(:error) { StandardError.new('this is test') }

  describe '#extract_error_info' do
    let(:error_info) { extractor.extract_error_info(error) }

    context 'when error without backtrace' do
      it { expect(error_info[0]).to eq('StandardError') }
      it { expect(error_info[1]).to eq('this is test') }
      it { expect(error_info[2]).to eq('') }
    end

    context 'when error with backtrace' do
      before { error.set_backtrace(caller) }

      it { expect(error_info[2]).not_to be_empty }

      it 'expect to return backtrace without the app full path' do
        expect(error_info[2]).not_to include(Karafka.root.to_s)
      end

      it 'expect to return backtrace without the gem home' do
        expect(error_info[2]).not_to include(Karafka.gem_root.to_s)
      end
    end
  end

  describe '#extract_error_message' do
    let(:extracted_message) { extractor.extract_error_message(error) }

    it { expect(extracted_message).to eq('this is test') }

    context 'when error message is extremely long' do
      let(:msg) { 'error' * 5_000 }
      let(:error) { StandardError.new(msg) }

      it 'expect to trim it to 10k of characters' do
        expect(extracted_message).to eq(msg[0, 10_000])
      end
    end
  end
end
