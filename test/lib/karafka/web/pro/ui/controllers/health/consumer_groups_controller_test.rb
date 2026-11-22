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
  let(:app) { Karafka::Web::Pro::Ui::App }

  let(:topic) { create_topic(partitions: 2) }
  let(:group_id) { SecureRandom.uuid }

  before do
    produce_many(topic, Array.new(10) { |i| i.to_s }, partition: 1)
    Karafka::Admin.seek_consumer_group(group_id, { topic => { 1 => 4 } })
  end

  describe "#index" do
    context "when listing all the consumer groups" do
      before { get "health/consumer_groups" }

      it "lists a group the Web UI does not manage with its state" do
        assert_ok
        assert_body(breadcrumbs)
        assert_body("Consumer Groups")
        assert_body(%(href="/health/consumer_groups/#{group_id}"))
        assert_body("empty")
      end
    end

    context "when filtering by the consumer group id" do
      before { get_filtered("health/consumer_groups", id: group_id) }

      it do
        assert_ok
        assert_body(%(href="/health/consumer_groups/#{group_id}"))
        refute_body("No results match your filter")
      end
    end

    context "when filtering finds nothing" do
      before { get_filtered("health/consumer_groups", id: "zzz-no-such-group") }

      it do
        assert_ok
        refute_body(%(href="/health/consumer_groups/#{group_id}"))
        assert_body("No results match your filter")
      end
    end

    context "when sorting by id descending" do
      let(:other_group_id) { "0-#{group_id}" }

      before do
        Karafka::Admin.seek_consumer_group(other_group_id, { topic => { 1 => 2 } })
        get "health/consumer_groups?sort=id+desc"
      end

      it do
        assert_ok
        assert(response.body.index(group_id) < response.body.index(other_group_id))
      end
    end
  end

  describe "#show" do
    context "when the consumer group does not exist" do
      before { get "health/consumer_groups/#{SecureRandom.uuid}" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when the consumer group has only committed offsets" do
      before { get "health/consumer_groups/#{group_id}" }

      it "shows its state, no members and the committed offsets with lags" do
        assert_ok
        assert_body(breadcrumbs)
        assert_body("empty")
        assert_body("This consumer group has no members.")
        assert_body(topic)
        assert_body("<td>4</td>")
        assert_body("<td>6</td>")
      end
    end

    context "when the consumer group has an active member" do
      let(:consumer) do
        Rdkafka::Config.new(
          "bootstrap.servers": "127.0.0.1:9092",
          "group.id": group_id,
          "client.id": "consumer-groups-controller-test"
        ).consumer
      end

      before do
        consumer.subscribe(topic)

        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30

        while consumer.assignment.empty?
          raise "no assignment" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

          consumer.poll(100)
        end

        get "health/consumer_groups/#{group_id}"
      end

      after { consumer.close }

      it "shows the member with its client id and assignment" do
        assert_ok
        assert_body("stable")
        assert_body("consumer-groups-controller-test")
        assert_body("#{topic}: 0, 1")
        refute_body("This consumer group has no members.")
      end
    end
  end
end
