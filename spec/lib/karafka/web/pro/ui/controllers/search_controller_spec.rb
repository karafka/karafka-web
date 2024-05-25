# frozen_string_literal: true

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  let(:topic) { create_topic(partitions: partitions) }
  let(:partitions) { 1 }
  let(:no_search_criteria) { 'No search criteria provided.' }
  let(:metadata_button) { 'id="toggle-search-metadata-btn"' }
  let(:search_modal) { 'id="messages-search-form"' }
  let(:search_modal_errors) { 'id="search-form-errors"' }
  let(:search_metadata) { 'id="search-metadata-details"' }
  let(:nothing_found) { 'No results found. Try aligning your search criteria.' }
  let(:valid_search) do
    <<~SEARCH.tr("\n", '&')
      search[matcher]=Raw+payload+includes
      search[phrase]=1
      search[partitions][]=all
      search[offset_type]=latest
      search[limit]=1000
    SEARCH
  end

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
      expect(body).to include(search_modal)
      expect(body).not_to include(search_modal_errors)
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
      expect(body).to include(search_modal)
      expect(body).not_to include(search_modal_errors)
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
      expect(body).to include(search_modal)
      expect(body).not_to include(search_modal_errors)
      expect(body).not_to include('table')
      expect(body).not_to include(pagination)
      expect(body).not_to include(support_message)
      expect(body).not_to include(metadata_button)
    end
  end

  context 'when searching with invalid matcher and missing attributes' do
    before { get "explorer/#{topic}/search?search[matcher]=invalid" }

    it do
      expect(response).to be_ok
      expect(body).to include(breadcrumbs)
      expect(body).to include(search_modal)
      expect(body).to include('matcher: is invalid')
      expect(body).to include('offset_type: is invalid')
      expect(body).to include(search_modal_errors)
      expect(body).not_to include('table')
      expect(body).not_to include(pagination)
      expect(body).not_to include(support_message)
      expect(body).not_to include(metadata_button)
    end
  end

  context 'when searching an empty topic' do
    before { get "explorer/#{topic}/search?#{valid_search}" }

    it do
      expect(response).to be_ok
      expect(body).to include(breadcrumbs)
      expect(body).to include(search_modal)
      expect(body).to include('table')
      expect(body).to include('Raw payload includes')
      expect(body).to include('Search criteria:')
      expect(body).to include('Total Messages Checked')
      expect(body).to include('Partition 0')
      expect(body).to include(metadata_button)
      expect(body).to include(search_metadata)
      expect(body).to include(nothing_found)
      expect(body).not_to include('Partition 1')
      expect(body).not_to include(no_search_criteria)
      expect(body).not_to include(search_modal_errors)
      expect(body).not_to include('matcher: is invalid')
      expect(body).not_to include(pagination)
      expect(body).not_to include(support_message)
    end
  end
end
