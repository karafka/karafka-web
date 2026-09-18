# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

describe_current do
  let(:runner) { described_class.new(topic, partitions_count, search_criteria) }

  context "when using mocked specs" do
    let(:topic) { "test_topic" }
    let(:partitions_count) { 3 }
    let(:search_criteria) do
      {
        matcher: Karafka::Web::Pro::Ui::Lib::Explorer::Search::Matchers::RawPayloadIncludes.name,
        limit: 10,
        offset: 0,
        offset_type: "latest",
        partitions: %w[0 1],
        phrase: "test phrase",
        timestamp: (Time.now.to_f * 1_000).to_i
      }
    end

    let(:matcher_instance) { stub(call: false) }
    let(:iterator_instance) { stub }

    4.times do |i|
      let(:"message#{i + 1}") do
        stub(partition: i % 2,
          offset: i,
          timestamp: Time.now - 10,
          clean!: nil,
          raw_payload: "",
          raw_headers: {})
      end
    end

    before do
      Karafka::Web::Pro::Ui::Lib::Explorer::Search::Matchers::RawPayloadIncludes.stubs(:new).returns(matcher_instance)

      Karafka::Pro::Iterator.stubs(:new).returns(iterator_instance)

      iterator_instance.stubs(:each).multiple_yields([message1], [message2], [message3], [message4])

      iterator_instance.stubs(:stop)

      iterator_instance.stubs(:stop_current_partition)
    end

    # L6: the "latest" start is a look-back, i.e. a NEGATIVE offset. `limit / partitions` floors
    # to zero once there are more partitions than the limit, and `0 * -1` is still `0`, which the
    # iterator reads as an absolute offset - so a "search from latest" silently scanned from the
    # oldest message.
    describe "the latest start offset" do
      let(:starts) do
        query = nil
        # the assignment returns the (truthy) query hash, so it doubles as the matcher
        Karafka::Pro::Iterator.stubs(:new).with { |q| query = q }.returns(iterator_instance)
        runner.call
        query.fetch(topic).values
      end

      context "when there are fewer partitions than the limit" do
        # limit 10 over partitions 0 and 1 -> 5 messages of look-back each
        it { assert_equal([-5, -5], starts) }
      end

      context "when there are more partitions than the limit" do
        let(:partitions_count) { 20 }

        before do
          search_criteria[:limit] = 5
          search_criteria[:partitions] = %w[all]
        end

        it "still looks back rather than collapsing to the oldest message" do
          assert_equal(20, starts.size)
          # every start must be a real look-back; `0` here would mean "from the beginning"
          assert(starts.all?(&:negative?), "expected negative look-backs, got #{starts.uniq}")
        end

        it "clamps to one message per partition" do
          assert_equal([-1], starts.uniq)
        end
      end
    end

    describe "#call" do
      it "returns the matched results and metrics" do
        results, metrics = runner.call

        assert_kind_of(Array, results)
        assert_kind_of(Hash, metrics)
        assert_kind_of(Hash, metrics[:totals])
        assert_kind_of(Hash, metrics[:partitions])
      end

      it "collects the correct metrics" do
        _results, metrics = runner.call

        assert_equal(4, metrics[:totals][:checked])
        assert_equal(0, metrics[:totals][:matched])
      end

      context "when a message matches the phrase" do
        before do
          matcher_instance.stubs(:call).returns(true)
        end

        it "adds the message to the matched results" do
          results, = runner.call

          assert_equal(4, results.size)
        end
      end

      context "when the total checked limit reach the limit" do
        let(:search_criteria) do
          {
            matcher: Karafka::Web::Pro::Ui::Lib::Explorer::Search::Matchers::RawPayloadIncludes.name,
            limit: 1,
            offset: 0,
            offset_type: "latest",
            partitions: %w[0 1],
            phrase: "test phrase",
            timestamp: (Time.now.to_f * 1_000).to_i
          }
        end

        before { iterator_instance.stubs(:stop) }

        it "stops the iterator" do
          iterator_instance.expects(:stop).at_least_once
          runner.call
        end
      end

      context "when the checked limit for a partition reach the limit" do
        let(:search_criteria) do
          {
            matcher: Karafka::Web::Pro::Ui::Lib::Explorer::Search::Matchers::RawPayloadIncludes.name,
            limit: 3,
            offset: 0,
            offset_type: "latest",
            partitions: %w[0 1],
            phrase: "test phrase",
            timestamp: (Time.now.to_f * 1_000).to_i
          }
        end

        before { iterator_instance.stubs(:stop_current_partition) }

        it "stops the current partition in the iterator" do
          iterator_instance.expects(:stop_current_partition).at_least_once
          runner.call
        end
      end
    end
  end

  # Search is also covered with controller specs
  context "when runningend to end search integrations" do
    let(:partitions_count) { 1 }

    let(:search_criteria) do
      {
        matcher: Karafka::Web::Pro::Ui::Lib::Explorer::Search::Matchers::RawPayloadIncludes.name,
        limit: 100,
        offset: 0,
        offset_type: "latest",
        partitions: %w[0 1],
        phrase: "test phrase",
        timestamp: Time.now.to_i
      }
    end

    context "when requested topic does not exist" do
      let(:topic) { generate_topic_name }

      it { assert_raises(Rdkafka::RdkafkaError) { runner.call } }
    end

    context "when topic exists but we want to search in a higher partition" do
      let(:topic) { create_topic }
      let(:partitions_count) { 1 }

      it { assert_equal([], runner.call.first) }
    end

    context "when we want to search in many partitions and all include some data" do
      let(:topic) { create_topic(partitions: 2) }
      let(:partitions_count) { 2 }

      before do
        produce(topic, "12 test phrase 12", partition: 0)
        produce(topic, "12 test phrase 12", partition: 1)
        produce(topic, "na", partition: 0)
        produce(topic, "na", partition: 1)
      end

      it { assert_equal(2, runner.call.first.size) }
    end

    context "when we want to search in one partition and others have data" do
      let(:topic) { create_topic(partitions: 2) }
      let(:partitions_count) { 2 }

      before do
        produce(topic, "12 test phrase 12", partition: 1)
        produce(topic, "na", partition: 0)
        produce(topic, "na", partition: 1)

        search_criteria[:partitions][0]
      end

      it { assert_equal(1, runner.call.first.size) }
    end

    context "when we want to search from beginning but what we want is ahead of our limits" do
      let(:topic) { create_topic }

      before do
        20.times { produce(topic, "na") }

        produce(topic, "12 test phrase 12", partition: 0)

        search_criteria[:limit] = 10
        search_criteria[:offset_type] = "offset"
        search_criteria[:offset] = 0
      end

      it { assert_equal(0, runner.call.first.size) }
    end

    context "when we want to search from beginning on many and divided does not reach" do
      let(:topic) { create_topic(partitions: 10) }
      let(:partitions_count) { 10 }

      before do
        10.times do |partition|
          12.times { produce(topic, "na", partition: partition) }
          produce(topic, "12 test phrase 12", partition: partition)
        end

        search_criteria[:limit] = 100
        search_criteria[:offset_type] = "offset"
        search_criteria[:offset] = 0
        search_criteria[:partitions] = %w[all]
      end

      it { assert_equal(0, runner.call.first.size) }
    end

    context "when we want to search from beginning on many and divided reaches" do
      let(:topic) { create_topic(partitions: 10) }
      let(:partitions_count) { 10 }

      before do
        10.times do |partition|
          produce(topic, "12 test phrase 12", partition: partition)
        end

        search_criteria[:limit] = 100
        search_criteria[:offset_type] = "offset"
        search_criteria[:offset] = 0
        search_criteria[:partitions] = %w[all]
      end

      it { assert_equal(10, runner.call.first.size) }
    end

    context "when searching with offset ahead of searched limit" do
      let(:topic) { create_topic(partitions: 10) }
      let(:partitions_count) { 10 }

      before do
        10.times do |partition|
          produce(topic, "12 test phrase 12", partition: partition)
        end

        sleep(1)

        search_criteria[:limit] = 100
        search_criteria[:offset_type] = "timestamp"
        search_criteria[:timestamp] = (Time.now.to_f * 1_000).to_i
        search_criteria[:partitions] = %w[all]
      end

      it { assert_equal(0, runner.call.first.size) }
    end

    context "when searching with offset behind of searched limit" do
      let(:topic) { create_topic(partitions: 10) }
      let(:partitions_count) { 10 }

      before do
        10.times do |partition|
          produce(topic, "12 test phrase 12", partition: partition)
        end

        sleep(1)

        search_criteria[:limit] = 100
        search_criteria[:offset_type] = "timestamp"
        search_criteria[:timestamp] = ((Time.now.to_f - 100) * 1_000).to_i
        search_criteria[:partitions] = %w[all]
      end

      it { assert_equal(10, runner.call.first.size) }
    end
  end
end
