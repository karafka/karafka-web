# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Ui::App }

  describe '#show' do
    before { get 'status' }

    it { expect(last_response).to be_ok }
  end
end
