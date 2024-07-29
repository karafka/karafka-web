# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  describe '#show' do
    before { get 'ux' }

    it do
      expect(response).to be_ok
      expect(body).not_to include(support_message)
      expect(body).to include(breadcrumbs)
    end
  end
end
