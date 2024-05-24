# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:topic) { create_topic(partitions: partitions) }
  let(:partitions) { 1 }
  let(:no_search_criteria) { 'No search criteria provided.' }
  let(:metadata_button) { 'id="toggleSearchMetadataBtn"' }

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
      expect(body).not_to include(metadata_button)
    end
  end

  context 'when requested topic exists and there is data but we did not run search' do
    before do
      produce_many(topic, %w[message])
      get "explorer/#{topic}/search"
    end

    it do
      expect(response).to be_ok
      expect(body).to include(breadcrumbs)
      expect(body).to include(no_search_criteria)
      expect(body).not_to include('table')
      expect(body).not_to include(pagination)
      expect(body).not_to include(support_message)
      expect(body).not_to include(metadata_button)
    end
  end

  context 'when requested topic exists and there is tombstone data but we did not run search' do
    before do
      produce_many(topic, [nil])
      get "explorer/#{topic}/search"
    end

    it do
      expect(response).to be_ok
      expect(body).to include(breadcrumbs)
      expect(body).to include(no_search_criteria)
      expect(body).not_to include('table')
      expect(body).not_to include(pagination)
      expect(body).not_to include(support_message)
      expect(body).not_to include(metadata_button)
    end
  end
end
