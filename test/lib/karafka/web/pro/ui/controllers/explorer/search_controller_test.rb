# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

describe_current do
  let(:app) { Karafka::Web::Pro::Ui::App }

  let(:topic) { create_topic(partitions: partitions) }
  let(:partitions) { 1 }
  let(:no_search_criteria) { "No search criteria provided." }
  let(:metadata_button) { 'id="toggle-search-metadata"' }
  let(:search_modal) { 'id="messages-search-form"' }
  let(:search_modal_errors) { "Please fix the following errors" }
  let(:search_metadata) { 'id="search-metadata-details"' }
  let(:nothing_found) { "No results found. Try aligning your search criteria." }
  let(:valid_search) do
    <<~SEARCH.tr("\n", "&")
      search[matcher]=Raw+payload+includes
      search[phrase]=find-me
      search[partitions][]=all
      search[offset_type]=latest
      search[limit]=1000
    SEARCH
  end

  context "when requested topic does not exist" do
    before { get "explorer/topic/search" }

    it do
      refute(response.ok?)
      assert_equal(404, response.status)
    end
  end

  context "when requested topic exists but there is no data" do
    before { get "explorer/#{topic}/search" }

    it do
      assert(response.ok?)
      assert_body(breadcrumbs)
      assert_body(no_search_criteria)
      assert_body(search_modal)
      assert_body(search_modal)
      assert_body("Raw payload includes")
      assert_body("Raw key includes")
      assert_body("Raw header includes")
      refute_body(search_modal_errors)
      refute_body("table")
      refute_body(pagination)
      refute_body(support_message)
      refute_body(metadata_button)
    end
  end

  context "when one of the matchers is not active for this topic" do
    before do
      Karafka::Web::Pro::Ui::Lib::Search::Matchers::RawHeaderIncludes.stubs(:active?).with(topic).returns(false)

      get "explorer/#{topic}/search"
    end

    it do
      assert(response.ok?)
      assert_body(breadcrumbs)
      assert_body(no_search_criteria)
      assert_body(search_modal)
      assert_body("Raw payload includes")
      assert_body("Raw key includes")
      refute_body("Raw header includes")
      refute_body(search_modal_errors)
      refute_body("table")
      refute_body(pagination)
      refute_body(support_message)
      refute_body(metadata_button)
    end
  end

  context "when requested topic exists and there is data but we did not run search" do
    before do
      produce_many(topic, %w[message])
      get "explorer/#{topic}/search"
    end

    it do
      assert(response.ok?)
      assert_body(breadcrumbs)
      assert_body(no_search_criteria)
      assert_body(search_modal)
      refute_body(search_modal_errors)
      refute_body("table")
      refute_body(pagination)
      refute_body(support_message)
      refute_body(metadata_button)
    end
  end

  context "when requested topic exists and there is tombstone data but we did not run search" do
    before do
      produce_many(topic, [nil])
      get "explorer/#{topic}/search"
    end

    it do
      assert(response.ok?)
      assert_body(breadcrumbs)
      assert_body(no_search_criteria)
      assert_body(search_modal)
      refute_body(search_modal_errors)
      refute_body("table")
      refute_body(pagination)
      refute_body(support_message)
      refute_body(metadata_button)
    end
  end

  context "when searching with invalid matcher and missing attributes" do
    before { get "explorer/#{topic}/search?search[matcher]=invalid" }

    it do
      assert(response.ok?)
      assert_body(breadcrumbs)
      assert_body(search_modal)
      assert_body("matcher: must match the existing matchers names")
      assert_body("offset_type: must be latest, offset or a timestamp")
      assert_body(search_modal_errors)
      refute_body("table")
      refute_body(pagination)
      refute_body(support_message)
      refute_body(metadata_button)
    end
  end

  context "when searching an empty topic" do
    before { get "explorer/#{topic}/search?#{valid_search}" }

    it do
      assert(response.ok?)
      assert_body(breadcrumbs)
      assert_body(search_modal)
      assert_body("table")
      assert_body("Raw payload includes")
      assert_body("Search criteria:")
      assert_body("Total Messages Checked")
      assert_body("Partition 0")
      assert_body(metadata_button)
      assert_body(search_metadata)
      assert_body(nothing_found)
      refute_body("Partition 1")
      refute_body(no_search_criteria)
      refute_body(search_modal_errors)
      refute_body("matcher: is invalid")
      refute_body(pagination)
      refute_body(support_message)
    end
  end

  context "when searching a topic that has matches only in the second partition" do
    let(:partitions) { 2 }

    before do
      produce_many(topic, %w[message message2 message 3], partition: 0)
      produce_many(topic, %w[find-me also-find-me find-me-and], partition: 1)

      get "explorer/#{topic}/search?#{valid_search}"
    end

    it do
      assert(response.ok?)
      assert_body(breadcrumbs)
      assert_body(search_modal)
      assert_body("table")
      assert_body("Raw payload includes")
      assert_body("Search criteria:")
      assert_body("Total Messages Checked")
      assert_body("Partition 0")
      assert_body("Partition 1")
      assert_body(metadata_button)
      assert_body(search_metadata)
      assert_body("<td>3</td>")
      refute_body(nothing_found)
      refute_body(no_search_criteria)
      refute_body(search_modal_errors)
      refute_body("matcher: is invalid")
      refute_body(pagination)
      refute_body(support_message)
    end
  end

  context "when searching a topic that has results but before the start timestamp" do
    let(:partitions) { 2 }
    let(:valid_search) do
      <<~SEARCH.tr("\n", "&")
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
      assert(response.ok?)
      assert_body(breadcrumbs)
      assert_body(search_modal)
      assert_body("table")
      assert_body("Raw payload includes")
      assert_body("Search criteria:")
      assert_body("Total Messages Checked")
      assert_body("Partition 0")
      assert_body("Partition 1")
      assert_body(metadata_button)
      assert_body(search_metadata)
      assert_body(nothing_found)
      refute_body(no_search_criteria)
      refute_body(search_modal_errors)
      refute_body("matcher: is invalid")
      refute_body(pagination)
      refute_body(support_message)
    end
  end

  context "when searching a topic that has results after the start timestamp" do
    let(:partitions) { 2 }
    let(:valid_search) do
      <<~SEARCH.tr("\n", "&")
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
      assert(response.ok?)
      assert_body(breadcrumbs)
      assert_body(search_modal)
      assert_body("table")
      assert_body("Raw payload includes")
      assert_body("Search criteria:")
      assert_body("Total Messages Checked")
      assert_body("Partition 0")
      assert_body("Partition 1")
      assert_body(metadata_button)
      assert_body(search_metadata)
      assert_body("<td>6</td>")
      refute_body(nothing_found)
      refute_body(no_search_criteria)
      refute_body(search_modal_errors)
      refute_body("matcher: is invalid")
      refute_body(pagination)
      refute_body(support_message)
    end
  end

  context "when searching a topic that has results but not in searched partition" do
    let(:partitions) { 4 }
    let(:valid_search) do
      <<~SEARCH.tr("\n", "&")
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
      assert(response.ok?)
      assert_body(breadcrumbs)
      assert_body(search_modal)
      assert_body("table")
      assert_body("Raw payload includes")
      assert_body("Search criteria:")
      assert_body("Total Messages Checked")
      assert_body("Partition 0")
      assert_body("Partition 1")
      assert_body("Partition 2")
      assert_body("Partition 3")
      assert_body(metadata_button)
      assert_body(search_metadata)
      assert_body(nothing_found)
      refute_body(no_search_criteria)
      refute_body(search_modal_errors)
      refute_body("matcher: is invalid")
      refute_body(pagination)
      refute_body(support_message)
    end
  end

  context "when searching a topic that has matches in a zlib compressed payload" do
    let(:partitions) { 2 }

    before do
      produce_many(
        topic,
        %w[message message2 message 3].map { |msg| Zlib.deflate(msg) },
        partition: 0,
        headers: { "zlib" => "true" }
      )

      produce_many(
        topic,
        %w[find-me also-find-me find-me-and].map { |msg| Zlib.deflate(msg) },
        partition: 1,
        headers: { "zlib" => "true" }
      )

      get "explorer/#{topic}/search?#{valid_search}"
    end

    it do
      assert(response.ok?)
      assert_body(breadcrumbs)
      assert_body(search_modal)
      assert_body("table")
      assert_body("Raw payload includes")
      assert_body("Search criteria:")
      assert_body("Total Messages Checked")
      assert_body("Partition 0")
      assert_body("Partition 1")
      assert_body(metadata_button)
      assert_body(search_metadata)
      assert_body("<td>3</td>")
      refute_body(nothing_found)
      refute_body(no_search_criteria)
      refute_body(search_modal_errors)
      refute_body("matcher: is invalid")
      refute_body(pagination)
      refute_body(support_message)
    end
  end
end
