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
      search[phrase]=find-me
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
      expect(body).to include('matcher: must match the existing matchers names')
      expect(body).to include('offset_type: must be latest, offset or a timestamp')
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

  context 'when searching a topic that has matches only in the second partition' do
    let(:partitions) { 2 }

    before do
      produce_many(topic, %w[message message2 message 3], partition: 0)
      produce_many(topic, %w[find-me also-find-me find-me-and], partition: 1)

      get "explorer/#{topic}/search?#{valid_search}"
    end

    it do
      expect(response).to be_ok
      expect(body).to include(breadcrumbs)
      expect(body).to include(search_modal)
      expect(body).to include('table')
      expect(body).to include('Raw payload includes')
      expect(body).to include('Search criteria:')
      expect(body).to include('Total Messages Checked')
      expect(body).to include('Partition 0')
      expect(body).to include('Partition 1')
      expect(body).to include(metadata_button)
      expect(body).to include(search_metadata)
      expect(body).to include('<td>3</td>')
      expect(body).not_to include(nothing_found)
      expect(body).not_to include(no_search_criteria)
      expect(body).not_to include(search_modal_errors)
      expect(body).not_to include('matcher: is invalid')
      expect(body).not_to include(pagination)
      expect(body).not_to include(support_message)
    end
  end

  context 'when searching a topic that has results but before the start timestamp' do
    let(:partitions) { 2 }
    let(:valid_search) do
      <<~SEARCH.tr("\n", '&')
        search[matcher]=Raw+payload+includes
        search[phrase]=find-me
        search[partitions][]=all
        search[offset_type]=timestamp
        search[timestamp]=#{(Time.now.to_f * 1_000).to_i}
        search[limit]=1000
      SEARCH
    end

    before do
      produce_many(topic, %w[find-me also-find-me find-me-and], partition: 0)
      produce_many(topic, %w[find-me also-find-me find-me-and], partition: 1)

      sleep(1)

      get "explorer/#{topic}/search?#{valid_search}"
    end

    it do
      expect(response).to be_ok
      expect(body).to include(breadcrumbs)
      expect(body).to include(search_modal)
      expect(body).to include('table')
      expect(body).to include('Raw payload includes')
      expect(body).to include('Search criteria:')
      expect(body).to include('Total Messages Checked')
      expect(body).to include('Partition 0')
      expect(body).to include('Partition 1')
      expect(body).to include(metadata_button)
      expect(body).to include(search_metadata)
      expect(body).to include(nothing_found)
      expect(body).not_to include(no_search_criteria)
      expect(body).not_to include(search_modal_errors)
      expect(body).not_to include('matcher: is invalid')
      expect(body).not_to include(pagination)
      expect(body).not_to include(support_message)
    end
  end

  context 'when searching a topic that has results after the start timestamp' do
    let(:partitions) { 2 }
    let(:valid_search) do
      <<~SEARCH.tr("\n", '&')
        search[matcher]=Raw+payload+includes
        search[phrase]=find-me
        search[partitions][]=all
        search[offset_type]=timestamp
        search[timestamp]=#{((Time.now.to_f - 100) * 1_000).to_i}
        search[limit]=1000
      SEARCH
    end

    before do
      produce_many(topic, %w[find-me also-find-me find-me-and], partition: 0)
      produce_many(topic, %w[find-me also-find-me find-me-and], partition: 1)

      get "explorer/#{topic}/search?#{valid_search}"
    end

    it do
      expect(response).to be_ok
      expect(body).to include(breadcrumbs)
      expect(body).to include(search_modal)
      expect(body).to include('table')
      expect(body).to include('Raw payload includes')
      expect(body).to include('Search criteria:')
      expect(body).to include('Total Messages Checked')
      expect(body).to include('Partition 0')
      expect(body).to include('Partition 1')
      expect(body).to include(metadata_button)
      expect(body).to include(search_metadata)
      expect(body).to include('<td>6</td>')
      expect(body).not_to include(nothing_found)
      expect(body).not_to include(no_search_criteria)
      expect(body).not_to include(search_modal_errors)
      expect(body).not_to include('matcher: is invalid')
      expect(body).not_to include(pagination)
      expect(body).not_to include(support_message)
    end
  end

  context 'when searching a topic that has results but not in searched partition' do
    let(:partitions) { 4 }
    let(:valid_search) do
      <<~SEARCH.tr("\n", '&')
        search[matcher]=Raw+payload+includes
        search[phrase]=find-me
        search[partitions][]=2
        search[partitions][]=3
        search[offset_type]=latest
        search[timestamp]=0
        search[limit]=1000
      SEARCH
    end

    before do
      produce_many(topic, %w[find-me also-find-me find-me-and], partition: 0)
      produce_many(topic, %w[find-me also-find-me find-me-and], partition: 1)

      sleep(1)

      get "explorer/#{topic}/search?#{valid_search}"
    end

    it do
      expect(response).to be_ok
      expect(body).to include(breadcrumbs)
      expect(body).to include(search_modal)
      expect(body).to include('table')
      expect(body).to include('Raw payload includes')
      expect(body).to include('Search criteria:')
      expect(body).to include('Total Messages Checked')
      expect(body).to include('Partition 0')
      expect(body).to include('Partition 1')
      expect(body).to include('Partition 2')
      expect(body).to include('Partition 3')
      expect(body).to include(metadata_button)
      expect(body).to include(search_metadata)
      expect(body).to include(nothing_found)
      expect(body).not_to include(no_search_criteria)
      expect(body).not_to include(search_modal_errors)
      expect(body).not_to include('matcher: is invalid')
      expect(body).not_to include(pagination)
      expect(body).not_to include(support_message)
    end
  end
end
