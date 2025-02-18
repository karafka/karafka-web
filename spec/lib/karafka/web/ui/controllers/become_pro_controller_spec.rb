# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  describe '#show' do
    before { get 'health/overview' }

    it do
      expect(response.status).to eq(402)
      expect(body).to include('This Web UI feature is available only to')
    end
  end
end
