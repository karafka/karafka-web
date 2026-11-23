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
  let(:stable_group_id) { "member-#{group_id}" }

  let(:group_protocol) { "classic" }

  let(:consumer) do
    Rdkafka::Config.new(
      Karafka::App.config.kafka.merge(
        "group.id": stable_group_id,
        "group.protocol": group_protocol,
        "client.id": "consumer-groups-controller-test"
      )
    ).consumer
  end

  def start_member
    consumer.subscribe(topic)

    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30

    while consumer.assignment.empty?
      raise "no assignment" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      consumer.poll(100)
    end
  end

  def position(text)
    response.body.index(text)
  end

  before do
    produce_many(topic, Array.new(10) { |i| i.to_s }, partition: 0)
    produce_many(topic, Array.new(20) { |i| i.to_s }, partition: 1)
    Karafka::Admin.seek_consumer_group(group_id, { topic => { 0 => 2, 1 => 5 } })
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
        assert(position(group_id) < position(other_group_id))
      end
    end

    context "when there is a stable and an empty consumer group" do
      let(:decoy_group_id) { "stable-#{group_id}" }

      before do
        Karafka::Admin.seek_consumer_group(decoy_group_id, { topic => { 1 => 1 } })
        start_member
      end

      after { consumer.close }

      it "expect filtering by state to keep only the matching group" do
        get_filtered("health/consumer_groups", state: "stable")

        assert_ok
        assert_body(%(href="/health/consumer_groups/#{stable_group_id}"))
        refute_body(%(href="/health/consumer_groups/#{group_id}"))
        refute_body(%(href="/health/consumer_groups/#{decoy_group_id}"))
      end

      it "expect sorting by state to order the groups by it" do
        get "health/consumer_groups?sort=state+asc"

        assert_ok
        assert(position("/#{group_id}\"") < position("/#{stable_group_id}\""))

        get "health/consumer_groups?sort=state+desc"

        assert_ok
        assert(position("/#{stable_group_id}\"") < position("/#{group_id}\""))
      end
    end

    context "when the consumer group id has characters that are special in URLs" do
      let(:special_group_id) { "a b/c?d#e%f-#{group_id}" }
      let(:special_path) { "/health/consumer_groups/a%20b%2Fc%3Fd%23e%25f-#{group_id}" }

      before do
        Karafka::Admin.seek_consumer_group(special_group_id, { topic => { 1 => 3 } })
        get_filtered("health/consumer_groups", id: group_id)
      end

      it "expect its link to lead to its page" do
        assert_ok
        assert_body(%(href="#{special_path}"))

        get special_path

        assert_ok
        assert_body("Consumer group #{special_group_id}")
        assert_body(%(href="#{special_path}"))
        assert_body("<td>3</td>")
      end
    end
  end

  describe "#show" do
    context "when the consumer group id is not ASCII" do
      let(:unicode_group_id) { "zażółć gęślą/#{group_id}" }
      let(:unicode_path) { "/health/consumer_groups/#{URI.encode_uri_component(unicode_group_id)}" }

      before do
        Karafka::Admin.seek_consumer_group(unicode_group_id, { topic => { 1 => 7 } })
        get_filtered("health/consumer_groups", id: group_id)
      end

      it "expect its link to lead to its page" do
        assert_ok
        assert_body(%(href="#{unicode_path}"))

        get unicode_path

        assert_ok
        assert_body("<td>7</td>")
        assert_body("<td>13</td>")
      end
    end

    context "when loading the consumer group page raises an ArgumentError" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).raises(ArgumentError)
        get "health/consumer_groups/#{group_id}"
      end

      it do
        refute(response.ok?)
        assert_equal(500, response.status)
      end
    end

    %w[%zz abc%].each do |malformed|
      context "when the consumer group id is a malformed escape (#{malformed})" do
        it do
          env = Rack::MockRequest.env_for("http://example.org/")
          env["PATH_INFO"] = "/health/consumer_groups/#{malformed}"

          assert_equal(404, app.call(env).first)
        end
      end
    end

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
        assert_body("<td>5</td>")
        assert_body("<td>15</td>")
      end
    end

    context "when sorting the partitions by lag" do
      it "expect the rows in the lag order" do
        get "health/consumer_groups/#{group_id}?sort=lag+desc"

        assert_ok
        assert(position("<td>15</td>") < position("<td>8</td>"))

        get "health/consumer_groups/#{group_id}?sort=lag+asc"

        assert_ok
        assert(position("<td>8</td>") < position("<td>15</td>"))
      end
    end

    context "when the consumer group has an active member" do
      let(:described) { Karafka::Admin.describe_consumer_groups([stable_group_id]).first }

      before do
        start_member
        get "health/consumer_groups/#{stable_group_id}"
      end

      after { consumer.close }

      it "shows the member with its client id, host and assignment, and the coordinator" do
        coordinator = described.fetch(:coordinator)

        assert_ok
        assert_body("stable")
        assert_body("consumer-groups-controller-test")
        assert_body("<td>#{described.fetch(:members).first.fetch(:host)}</td>")
        assert_body("#{coordinator[:id]} (#{coordinator[:host]}:#{coordinator[:port]})")
        assert_body("#{topic}: 0, 1")
        refute_body("This consumer group has no members.")
        refute_body("Target assignment")
      end

      context "when the group uses the consumer (KIP-848) protocol" do
        let(:group_protocol) { "consumer" }

        it "shows the member current and target assignment" do
          assert_ok
          assert_body("stable")
          assert_body("<th>Target assignment</th>")
          assert_equal(2, response.body.scan("#{topic}: 0, 1").size)
        end
      end
    end
  end
end
