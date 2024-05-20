# frozen_string_literal: true

RSpec.describe_current do
  subject(:enable) { described_class.new.call }

  context 'when karafka framework is not initialized' do
    before do
      allow(Karafka::App.config.internal.status)
        .to receive(:initializing?)
        .and_return(true)
    end

    it 'expect not to allow for enabling of web-ui' do
      expect { enable }.to raise_error(Karafka::Web::Errors::KarafkaNotInitializedError)
    end
  end
end
