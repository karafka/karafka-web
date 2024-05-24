# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:topic) { create_topic(partitions: partitions) }
  let(:partitions) { 1 }
  let(:no_search_criteria) { 'No search criteria provided.' }

  context 'when requested topic does not exist' do
    before { get 'explorer/topic/search' }

    it do
      expect(response).not_to be_ok
      expect(response.status).to eq(404)
    end
  end

  context 'when requested topic exists but there is no data' do
    before { get "explorer/#{topic}/search" }

    it do
      expect(response).to be_ok
      expect(body).to include(breadcrumbs)
      expect(body).to include(no_search_criteria)
      expect(body).not_to include('table')
      expect(body).not_to include(pagination)
      expect(body).not_to include(support_message)
    end
  end
end
