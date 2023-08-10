# frozen_string_literal: true

# We use this spec to check that pro components are not available when not in pro
RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  let(:make_better) { 'Please help us make the Karafka ecosystem better' }

  describe '#health' do
    before { get 'health' }

    it do
      expect(response).not_to be_ok
      expect(body).to include(make_better)
      expect(status).to eq(402)
    end
  end

  describe '#explorer' do
    before { get 'explorer' }

    it do
      expect(response).not_to be_ok
      expect(body).to include(make_better)
      expect(status).to eq(402)
    end
  end

  describe '#dlq' do
    before { get 'dlq' }

    it do
      expect(response).not_to be_ok
      expect(body).to include(make_better)
      expect(status).to eq(402)
    end
  end
end
