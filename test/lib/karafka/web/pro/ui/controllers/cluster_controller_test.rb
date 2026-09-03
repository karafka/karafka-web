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

  describe "#index" do
    before { get "cluster" }

    it do
      assert_ok
      assert_body("ID")
      assert_body(breadcrumbs)
      # The brokers filter selector exposes the columns actually displayed (node id + name)
      assert_body('value="id"')
      assert_body(">Node ID<")
      assert_body('value="name"')
    end

    context "when sorting the nodes" do
      before { get "cluster?sort=name+desc" }

      it do
        assert_ok
        assert_body("127.0.0.1")
      end
    end

    context "when filtering the nodes by a matching keyword" do
      before { get_filtered("cluster", "127.0.0.1") }

      it do
        assert_ok
        assert_body("127.0.0.1")
        refute_body("No results match your filter")
      end
    end

    context "when filtering the nodes by a non-matching keyword" do
      before { get_filtered("cluster", "zzz-no-such-node") }

      it do
        assert_ok
        assert_body("No results match your filter")
        refute_body("127.0.0.1")
      end
    end

    context "when requests policy prevents us from visiting this page" do
      before do
        Karafka::Web.config.ui.policies.requests.stubs(:allow?).returns(false)

        get "cluster"
      end

      it do
        refute(response.ok?)
        assert_equal(403, response.status)
      end
    end
  end

  describe "#show" do
    context "when broker with given id does not exist" do
      before { get "cluster/123" }

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when broker with given id exists" do
      before { get "cluster/1" }

      it do
        assert_ok
        assert_body(breadcrumbs)
        assert_body("advertised.listeners")
        assert_body("controller.quota.window.num")
        assert_body("log.flush.interval.ms")
        assert_body("9223372036854775807")
      end
    end

    context "when sorting the broker config" do
      before { get "cluster/1?sort=name+desc" }

      it do
        assert_ok
        assert_body("advertised.listeners")
      end
    end

    context "when filtering the broker config by a matching keyword" do
      before { get_filtered("cluster/1", "advertised") }

      it do
        assert_ok
        assert_body("advertised.listeners")
        refute_body("No results match your filter")
      end
    end

    context "when filtering the broker config by a non-matching keyword" do
      before { get_filtered("cluster/1", "zzz-no-such-config") }

      it do
        assert_ok
        # The filter emptied the table, so we show the filter-specific empty state instead of a
        # bare header-only table
        assert_body("No results match your filter")
        refute_body("advertised.listeners")
      end
    end
  end

  describe "#replication" do
    let(:topic) { create_topic(partitions: 1) }

    before do
      topic
      get "cluster/replication"
    end

    it do
      assert_ok
      assert_body(breadcrumbs)
    end

    it "links the replica/in-sync broker badges to the broker details page" do
      assert_ok
      # Single-broker cluster: leader/replica/isr are all broker 1
      assert_body('title="Broker 1 details"')
      assert_body("cluster/1\"")
    end

    context "when there are many pages with topics" do
      before { 30.times { create_topic } }

      context "when we visit existing page" do
        before { get "cluster/replication?page=2" }

        it do
          assert_ok
          assert_body(breadcrumbs)
          assert_body(pagination)
        end
      end

      context "when we visit a non-existing page" do
        before { get "cluster/replication?page=100000000" }

        it do
          assert_ok
          assert_body(pagination)
          assert_body(no_meaningful_results)
        end
      end
    end

    context "when sorting the partitions" do
      # `displayable_topics` pre-sorts topics alphabetically (alpha, beta), so a descending sort by
      # topic name must reverse that (beta before alpha) — which only happens if the sort is really
      # applied. All leaders point at the existing broker 1 so the crawled badge links resolve.
      let(:fake_topics) do
        [
          {
            topic_name: "beta_topic",
            partition_count: 1,
            partitions: [
              { partition_id: 0, leader: 1, replica_count: 1, in_sync_replica_brokers: 1, replicas: [1], isrs: [1] }
            ]
          },
          {
            topic_name: "alpha_topic",
            partition_count: 1,
            partitions: [
              { partition_id: 0, leader: 1, replica_count: 1, in_sync_replica_brokers: 1, replicas: [1], isrs: [1] }
            ]
          }
        ]
      end
      let(:fake_brokers) do
        [{ broker_id: 1, broker_name: "10.0.0.1", broker_port: 9092 }]
      end

      before do
        Karafka::Web::Ui::Models::ClusterInfo
          .stubs(:fetch)
          .returns(stub(topics: fake_topics, brokers: fake_brokers))
      end

      it "reorders the rows ascending by topic name" do
        get "cluster/replication?sort=topic_name+asc"

        assert_ok
        assert_operator(response.body.index("alpha_topic"), :<, response.body.index("beta_topic"))
      end

      it "reorders the rows descending by topic name" do
        get "cluster/replication?sort=topic_name+desc"

        assert_ok
        assert_operator(response.body.index("beta_topic"), :<, response.body.index("alpha_topic"))
      end
    end

    context "when filtering by topic name" do
      let(:partition) do
        { partition_id: 0, leader: 1, replica_count: 1, in_sync_replica_brokers: 1, replicas: [1], isrs: [1] }
      end
      let(:fake_topics) do
        [
          # partition_count is needed so the crawled /topics page can render these stubbed topics
          { topic_name: "orders_topic", partition_count: 1, partitions: [partition] },
          { topic_name: "payments_topic", partition_count: 1, partitions: [partition] }
        ]
      end
      let(:fake_brokers) do
        [{ broker_id: 1, broker_name: "10.0.0.1", broker_port: 9092 }]
      end

      before do
        Karafka::Web::Ui::Models::ClusterInfo
          .stubs(:fetch)
          .returns(stub(topics: fake_topics, brokers: fake_brokers))
      end

      it "keeps only the matching topic" do
        get_filtered("cluster/replication", "orders")

        assert_ok
        assert_body("orders_topic")
        refute_body("payments_topic")
        # Cluster exposes more than one filterable attribute, so a field selector is rendered
        assert_body('name="filter[value]"')
      end

      it "shows the no-results state when nothing matches" do
        get_filtered("cluster/replication", "zzz-no-such-topic")

        assert_ok
        assert_body("No results match your filter")
        refute_body("orders_topic")
      end
    end
  end

  describe "#distribution" do
    let(:topic) { create_topic(partitions: 2) }

    before do
      topic
      get "cluster/distribution"
    end

    it "renders the per-broker partition distribution" do
      assert_ok
      assert_body(breadcrumbs)
      assert_body("Leader partitions")
      assert_body("Replica partitions")
      # the imbalance highlighting column
      assert_body("Balance")
      # single-broker test cluster -> node 127.0.0.1 shows up as a row
      assert_body("127.0.0.1")
      # the Distribution tab links here
      assert_body("cluster/distribution")
    end

    it "exposes the distribution filter fields (node id + name)" do
      assert_ok
      assert_body('value="broker_id"')
      assert_body('value="broker_name"')
    end

    context "when sorting by a distribution column" do
      before { get "cluster/distribution?sort=leader_count+desc" }

      it { assert_ok }
    end

    context "when filtering by a matching node" do
      before { get_filtered("cluster/distribution", "127.0.0.1") }

      it do
        assert_ok
        assert_body("127.0.0.1")
      end
    end

    context "when filtering by a non-matching node" do
      before { get_filtered("cluster/distribution", "zzz-no-such-node") }

      it do
        assert_ok
        assert_body("No results match your filter")
      end
    end
  end
end
