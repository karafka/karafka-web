# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  describe '#show' do
    before { get 'support' }

    it do
      expect(response).to be_ok
      expect(body).to include(support_message)
      expect(body).to include(breadcrumbs)
    end
  end
end
