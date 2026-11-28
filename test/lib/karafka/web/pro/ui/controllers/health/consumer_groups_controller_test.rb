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
        "client.id": "consumer-groups-controller-test",
        "enable.auto.commit": false
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

  # Lists are paginated with the configured page size, which the per_page param does not change
  def paginate_by(per_page)
    Karafka::Web.config.ui.stubs(:per_page).returns(per_page)
  end

  before do
    produce_many(topic, Array.new(10) { |i| i.to_s }, partition: 0)
    produce_many(topic, Array.new(20) { |i| i.to_s }, partition: 1)
    Karafka::Admin.seek_consumer_group(group_id, { topic => { 0 => 2, 1 => 5 } })
  end

  describe "#index" do
    # The shared test cluster has more groups than fit on a page, so we search for ours
    context "when listing all the consumer groups" do
      before { get_filtered("health/consumer_groups", group_id) }

      it "lists a group the Web UI does not manage with its state" do
        assert_ok
        assert_body(breadcrumbs)
        assert_body("Consumer Groups")
        assert_body(%(href="/health/consumer_groups/#{group_id}/overview"))
        assert_body("empty")
      end
    end

    context "when filtering by the consumer group id" do
      before { get_filtered("health/consumer_groups", id: group_id) }

      it do
        assert_ok
        assert_body(%(href="/health/consumer_groups/#{group_id}/overview"))
        refute_body("No results match your filter")
      end
    end

    context "when filtering finds nothing" do
      before { get_filtered("health/consumer_groups", id: "zzz-no-such-group") }

      it do
        assert_ok
        refute_body(%(href="/health/consumer_groups/#{group_id}/overview"))
        assert_body("No results match your filter")
      end
    end

    context "when sorting by id descending" do
      let(:other_group_id) { "0-#{group_id}" }

      before do
        Karafka::Admin.seek_consumer_group(other_group_id, { topic => { 1 => 2 } })
        get_filtered("health/consumer_groups", id: group_id, sort: "id desc")
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
        assert_body(%(href="/health/consumer_groups/#{stable_group_id}/overview"))
        refute_body(%(href="/health/consumer_groups/#{group_id}/overview"))
        refute_body(%(href="/health/consumer_groups/#{decoy_group_id}/overview"))
      end

      it "expect sorting by state to order the groups by it" do
        get_filtered("health/consumer_groups", id: group_id, sort: "state asc")

        assert_ok
        assert(position("/#{group_id}/overview\"") < position("/#{stable_group_id}/overview\""))

        get_filtered("health/consumer_groups", id: group_id, sort: "state desc")

        assert_ok
        assert(position("/#{stable_group_id}/overview\"") < position("/#{group_id}/overview\""))
      end
    end

    context "when there are more consumer groups than fit on a page" do
      let(:other_group_id) { "0-#{group_id}" }

      before do
        Karafka::Admin.seek_consumer_group(other_group_id, { topic => { 1 => 2 } })
        paginate_by(1)
        get_filtered("health/consumer_groups", id: group_id)
      end

      it "expect the groups to be paginated" do
        assert_ok
        assert_body(pagination)
        assert_body(%(href="/health/consumer_groups/#{other_group_id}/overview"))
        refute_body(%(href="/health/consumer_groups/#{group_id}/overview"))
      end
    end

    context "when the page is past the last one" do
      before { get "health/consumer_groups?page=100000" }

      it do
        assert_ok
        refute_body(%(href="/health/consumer_groups/#{group_id}/overview"))
        assert_body("This page does not contain any data")
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
        assert_body(%(href="#{special_path}/overview"))

        get "#{special_path}/overview"

        assert_ok
        assert_body("Consumer group #{special_group_id}")
        assert_body(%(href="#{special_path}/offsets"))

        get "#{special_path}/offsets"

        assert_ok
        assert_body("<td>3</td>")
      end
    end
  end

  describe "consumer group pages" do
    context "when the consumer group id is not ASCII" do
      let(:unicode_group_id) { "zażółć gęślą/#{group_id}" }
      let(:unicode_path) { "/health/consumer_groups/#{URI.encode_uri_component(unicode_group_id)}" }

      before do
        Karafka::Admin.seek_consumer_group(unicode_group_id, { topic => { 1 => 7 } })
        get_filtered("health/consumer_groups", id: group_id)
      end

      it "expect its link to lead to its page" do
        assert_ok
        assert_body(%(href="#{unicode_path}/overview"))

        get "#{unicode_path}/offsets"

        assert_ok
        assert_body("<td>7</td>")
        assert_body("<td>13</td>")
      end
    end

    context "when opening the consumer group path without a page" do
      before { get "health/consumer_groups/#{group_id}" }

      it "expect a redirect to its overview" do
        assert_equal(302, response.status)
        assert(response.location.end_with?("/health/consumer_groups/#{group_id}/overview"))
      end
    end

    context "when loading the committed offsets raises an ArgumentError" do
      before do
        Karafka::Admin.stubs(:read_lags_with_offsets).raises(ArgumentError)
        get "health/consumer_groups/#{group_id}/offsets"
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
          env["PATH_INFO"] = "/health/consumer_groups/#{malformed}/overview"

          assert_equal(404, app.call(env).first)
        end
      end
    end

    %w[overview members offsets].each do |page|
      context "when the consumer group does not exist (#{page})" do
        before { get "health/consumer_groups/#{SecureRandom.uuid}/#{page}" }

        it do
          refute(response.ok?)
          assert_equal(404, response.status)
        end
      end
    end

    context "when the consumer group is deleted after it is listed" do
      before do
        Karafka::Admin
          .stubs(:describe_consumer_groups)
          .raises(Rdkafka::RdkafkaError.new(69))

        get "health/consumer_groups/#{group_id}/overview"
      end

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when the consumer group page does not exist" do
      before { get "health/consumer_groups/#{group_id}/unknown" }

      it do
        refute(response.ok?)
        assert_equal(404, response.status)
      end
    end

    context "when the consumer group has only committed offsets" do
      it "expect the overview to show its state with the tabs replacing the Health ones" do
        get "health/consumer_groups/#{group_id}/overview"

        assert_ok
        assert_body(breadcrumbs)
        assert_body("empty")
        assert_body("Members (0)")
        assert_body(%(href="/health/consumer_groups/#{group_id}/members"))
        assert_body(%(href="/health/consumer_groups/#{group_id}/offsets"))
        refute_body(%(href="/health/cluster_lags"))
      end

      it "expect the members page to show it has no members" do
        get "health/consumer_groups/#{group_id}/members"

        assert_ok
        assert_body(breadcrumbs)
        assert_body("This consumer group has no members.")
        refute_body(topic)
      end

      it "expect the committed offsets page to show the offsets with lags" do
        get "health/consumer_groups/#{group_id}/offsets"

        assert_ok
        assert_body(breadcrumbs)
        assert_body("Committed Offsets")
        assert_body(topic)
        assert_body("<td>5</td>")
        assert_body("<td>15</td>")
        refute_body("This consumer group has no committed offsets.")
      end
    end

    context "when the consumer group has no committed offsets" do
      before do
        start_member
        get "health/consumer_groups/#{stable_group_id}/offsets"
      end

      after { consumer.close }

      it do
        assert_ok
        assert_body("This consumer group has no committed offsets.")
      end
    end

    context "when listing the topics of the consumer group" do
      let(:other_topic) { create_topic }

      before do
        produce_many(other_topic, Array.new(50) { |i| i.to_s })
        Karafka::Admin.seek_consumer_group(group_id, { other_topic => { 0 => 10 } })
      end

      it "expect one row per topic with its aggregated lags and the offsets deletion" do
        get "health/consumer_groups/#{group_id}/topics"

        assert_ok
        assert_body(breadcrumbs)
        assert_body(%(href="/health/consumer_groups/#{group_id}/topics"))
        assert_body(
          "/health/consumer_groups/#{group_id}/offsets" \
          "?filter[field]=topic_name&amp;filter[value]=#{other_topic}"
        )
        # topic: 8 + 15 lag, other_topic: 40 lag
        assert_body("23")
        assert_body("40")
        assert_body('title="Highest lag is on partition 1"')
        assert_match(%r{\[1\]\s*</a>}, body)
        assert_body("filter[value]=#{topic}&amp;sort=lag+desc")
        # The default policy denies the deletion, so the button is disabled with the reason
        assert_body("Deleting these offsets is not allowed by the Web UI policies")
      end

      it "expect the deletion to be allowed only by the policy" do
        Karafka::Web.config.ui.policies.consumer_groups.stubs(:delete_offsets?).returns(true)

        get "health/consumer_groups/#{group_id}/topics"

        assert_ok
        assert_body(%(href="/health/consumer_groups/#{group_id}/topics/#{topic}/delete"))
        assert_body(%(href="/health/consumer_groups/#{group_id}/topics/#{other_topic}/delete"))
      end

      it "expect sorting by total lag to order the topics" do
        get "health/consumer_groups/#{group_id}/topics?sort=lag+desc"

        assert_ok
        assert(position("filter[value]=#{other_topic}") < position("filter[value]=#{topic}"))
      end

      it "expect filtering by the topic to keep only it" do
        get_filtered("health/consumer_groups/#{group_id}/topics", name: other_topic)

        assert_ok
        assert_body("filter[value]=#{other_topic}")
        refute_body("filter[value]=#{topic}\"")
      end

      it "expect the topics to be paginated" do
        paginate_by(1)
        get "health/consumer_groups/#{group_id}/topics"

        assert_ok
        assert_body(pagination)
      end
    end

    context "when the consumer group has no committed offsets on any topic" do
      before do
        start_member
        get "health/consumer_groups/#{stable_group_id}/topics"
      end

      after { consumer.close }

      it do
        assert_ok
        assert_body("This consumer group has no committed offsets.")
      end
    end

    context "when sorting the partitions by lag" do
      it "expect the rows in the lag order" do
        get "health/consumer_groups/#{group_id}/offsets?sort=lag+desc"

        assert_ok
        assert(position("<td>15</td>") < position("<td>8</td>"))

        get "health/consumer_groups/#{group_id}/offsets?sort=lag+asc"

        assert_ok
        assert(position("<td>8</td>") < position("<td>15</td>"))
      end
    end

    context "when the consumer group has an active member" do
      let(:described) { Karafka::Admin.describe_consumer_groups([stable_group_id]).first }

      before { start_member }

      after { consumer.close }

      it "expect the overview to show its state and coordinator" do
        get "health/consumer_groups/#{stable_group_id}/overview"

        coordinator = described.fetch(:coordinator)

        assert_ok
        assert_body("stable")
        assert_body("Members (1)")
        assert_body("#{coordinator[:id]} (#{coordinator[:host]}:#{coordinator[:port]})")
      end

      it "expect the members page to show the member with its client id, host and assignment" do
        get "health/consumer_groups/#{stable_group_id}/members"

        assert_ok
        assert_body("consumer-groups-controller-test")
        assert_body("<td>#{described.fetch(:members).first.fetch(:host)}</td>")
        assert_body("#{topic}-[0-1]")
        refute_body("This consumer group has no members.")
        refute_body("Target assignment")
      end

      context "when the consumer group uses the consumer (KIP-848) protocol" do
        let(:group_protocol) { "consumer" }

        it "expect the members page to show the current and the target assignment" do
          get "health/consumer_groups/#{stable_group_id}/members"

          assert_ok
          assert_body("<th>Target assignment</th>")
          assert_equal(2, response.body.scan(%(title="#{topic}-[0-1] (2 partitions total)")).size)
        end
      end
    end

    context "when the consumer group has many members" do
      let(:members) do
        %w[b a c].map do |name|
          {
            member_id: "member-#{name}",
            client_id: "client-#{name}",
            group_instance_id: nil,
            host: "/10.0.0.#{name.ord}",
            assignment: { topic => [name.ord % 2] },
            target_assignment: nil
          }
        end
      end

      before do
        described = Karafka::Admin.describe_consumer_groups([group_id]).first

        Karafka::Admin
          .stubs(:describe_consumer_groups)
          .returns([described.merge(members: members)])
      end

      it "expect the members to be paginated with the total in the tab" do
        paginate_by(2)
        get "health/consumer_groups/#{group_id}/members"

        assert_ok
        assert_body(pagination)
        assert_body("Members (3)")
        assert_body("client-b")
        assert_body("client-a")
        refute_body("client-c")
      end

      it "expect sorting by the client id to order them by it" do
        get "health/consumer_groups/#{group_id}/members?sort=client_id+desc"

        assert_ok
        assert(position("client-c") < position("client-b"))
        assert(position("client-b") < position("client-a"))
      end

      it "expect filtering by the host to keep only the matching member" do
        get_filtered("health/consumer_groups/#{group_id}/members", host: "10.0.0.#{"c".ord}")

        assert_ok
        assert_body("Members (3)")
        assert_body("client-c")
        refute_body("client-a")
        refute_body("client-b")
      end

      it "expect a filter that matches nothing to say so" do
        get_filtered("health/consumer_groups/#{group_id}/members", client_id: "zzz")

        assert_ok
        assert_body("No results match your filter")
      end

      it "expect a page past the last one to say it has no data" do
        get "health/consumer_groups/#{group_id}/members?page=100"

        assert_ok
        assert_body("This page does not contain any data")
      end
    end

    context "when the consumer group has committed offsets on many topics" do
      let(:other_topic) { create_topic }

      before do
        produce_many(other_topic, Array.new(50) { |i| i.to_s })
        Karafka::Admin.seek_consumer_group(group_id, { other_topic => { 0 => 10 } })
      end

      # Partitions are ordered by topic name and the topics names are random, so we only check
      # that each of the three partitions is on exactly one of the two pages
      it "expect the offsets to be paginated across topics" do
        paginate_by(2)
        get "health/consumer_groups/#{group_id}/offsets"

        assert_ok
        assert_body(pagination)
        first_page = body

        get "health/consumer_groups/#{group_id}/offsets?page=2"

        assert_ok
        second_page = body

        %w[8 15 40].each do |lag|
          assert_equal(
            1,
            [first_page, second_page].count { |page| page.include?("<td>#{lag}</td>") },
            "lag #{lag} should be on exactly one page"
          )
        end
      end

      it "expect sorting by lag to order the partitions of all the topics" do
        get "health/consumer_groups/#{group_id}/offsets?sort=lag+desc"

        assert_ok
        assert(position("<td>40</td>") < position("<td>15</td>"))
        assert(position("<td>15</td>") < position("<td>8</td>"))
      end

      it "expect filtering by the topic to keep only its partitions" do
        get_filtered("health/consumer_groups/#{group_id}/offsets", topic_name: other_topic)

        assert_ok
        assert_body("<td>40</td>")
        refute_body("<td>15</td>")
      end

      it "expect a page past the last one to say it has no data" do
        get "health/consumer_groups/#{group_id}/offsets?page=100"

        assert_ok
        assert_body("This page does not contain any data")
      end
    end

    context "when a member target assignment differs from its current one" do
      before do
        described = Karafka::Admin.describe_consumer_groups([group_id]).first

        member = {
          member_id: "moving-member",
          client_id: "moving-app",
          group_instance_id: nil,
          host: "/10.0.0.3",
          assignment: { topic => [0, 1] },
          target_assignment: { topic => [1] }
        }

        Karafka::Admin
          .stubs(:describe_consumer_groups)
          .returns([described.merge(members: [member])])

        get "health/consumer_groups/#{group_id}/members"
      end

      it "expect the target assignment column to show the target, not the current one" do
        assert_ok
        assert_body("<th>Target assignment</th>")
        assert_body("#{topic}-[1]")
        assert_equal(1, response.body.scan("#{topic}-[0,1]").size)
      end
    end

    context "when a member runs in a Karafka process that reports to the Web UI" do
      let(:report) { Fixtures.consumers_reports_json }
      let(:member_id) { "karafka-1c5e2b3a-7d4f-4e8a-b6c9-0f2a3d4e5b6c" }

      let(:members) do
        [
          {
            member_id: member_id,
            client_id: "karafka",
            group_instance_id: nil,
            host: "/10.0.0.1",
            assignment: { topic => [0] },
            target_assignment: nil
          },
          {
            member_id: "other-app-member",
            client_id: "other-app",
            group_instance_id: nil,
            host: "/10.0.0.2",
            assignment: { topic => [1] },
            target_assignment: nil
          }
        ]
      end

      before do
        described = Karafka::Admin.describe_consumer_groups([group_id]).first

        Karafka::Admin
          .stubs(:describe_consumer_groups)
          .returns([described.merge(members: members)])

        Karafka::Web::Ui::Models::ConsumersState.stubs(:current).returns({})
        Karafka::Web::Ui::Models::Processes
          .stubs(:active)
          .returns([Karafka::Web::Ui::Models::Process.new(report)])

        get "health/consumer_groups/#{group_id}/members"
      end

      it "expect to link the member to its process subscription group" do
        assert_ok
        assert_body("<th>Process</th>")
        assert_body(%(href="/consumers/shinra:1:1/subscriptions#c4ca4238a0b9_0"))
        assert_equal(1, response.body.scan("/consumers/shinra:1:1/subscriptions#").size)
      end

      it "expect a member of an application that does not report to show it has no process" do
        assert_ok
        assert_body("other-app")
        assert_equal(1, response.body.scan("Not a Karafka process reporting to the Web UI").size)
      end

      context "when the process id is longer than the shown part" do
        let(:process_id) { "#{"a" * 60}:1:1" }
        let(:report) { Fixtures.consumers_reports_json.tap { |r| r[:process][:id] = process_id } }

        it "expect to show it shortened with the full id in the title" do
          assert_ok
          assert_body(%(<span title="#{process_id}">#{"a" * 23}...#{"a" * 19}:1:1</span>))
          refute_body("&lt;span")
        end
      end
    end

    context "when there is no consumers state" do
      before do
        Karafka::Web::Ui::Models::ConsumersState.stubs(:current).returns(false)
        start_member
        get "health/consumer_groups/#{stable_group_id}/members"
        # The links of the page are validated after the spec and would otherwise reach pages
        # that require the consumers state (the dashboard) with it still missing
        Karafka::Web::Ui::Models::ConsumersState.unstub(:current)
      end

      after { consumer.close }

      it "expect to list the members without process links" do
        assert_ok
        assert_body("consumer-groups-controller-test")
        assert_body("Not a Karafka process reporting to the Web UI")
        refute_body("/subscriptions#")
      end
    end

    context "when Kafka reports the consumer group protocol" do
      before do
        described = Karafka::Admin.describe_consumer_groups([group_id]).first

        Karafka::Admin
          .stubs(:describe_consumer_groups)
          .returns([described.merge(type: :consumer)])

        get "health/consumer_groups/#{group_id}/overview"
      end

      it do
        assert_ok
        assert_body("<td>Protocol</td>")
        assert_body("<td>consumer</td>")
      end
    end

    context "when the protocol is not available" do
      before do
        described = Karafka::Admin.describe_consumer_groups([group_id]).first

        Karafka::Admin
          .stubs(:describe_consumer_groups)
          .returns([described.except(:type)])

        get "health/consumer_groups/#{group_id}/overview"
      end

      it do
        assert_ok
        refute_body("<td>Protocol</td>")
      end
    end
  end
end
