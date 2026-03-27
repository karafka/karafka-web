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

  let(:topic) { create_topic(partitions: partitions) }
  let(:partitions) { 1 }

  describe "#show" do
    context "when trying to read configs of a non-existing topic" do
      before { get "topics/#{generate_topic_name}/replication" }

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when getting replication of an existing topic with single partition" do
      before { get "topics/#{topic}/replication" }

      it do
        assert(response.ok?)
        assert_body(breadcrumbs)
        refute_body(pagination)
        refute_body(support_message)
        assert_body(topic)
        assert_body("Replica Count")
        assert_body("In Sync Brokers")
      end

      it "shows partition details" do
        assert_body("Partition")
        assert_body("Leader")
        assert_body("0") # First partition
      end

      it "displays replication settings cards" do
        assert_body("Replication Factor")
        assert_body("Min In-Sync Replicas")
        assert_body("Fault Tolerance")
      end
    end

    context "when topic has multiple partitions" do
      let(:partitions) { 5 }

      before { get "topics/#{topic}/replication" }

      it "displays all partitions" do
        assert(response.ok?)
        assert_body(topic)
        assert_body("0")
        assert_body("1")
        assert_body("2")
        assert_body("3")
        assert_body("4")
      end

      it "shows replication details for each partition" do
        assert_body("Replica Count")
        assert_body("In Sync Brokers")
        assert_body("Leader")
      end
    end

    context "when replication factor is 1 (no redundancy)" do
      # In the test environment, RF=1 by default (single broker setup)
      # This triggers the no redundancy warning

      context "when in production environment" do
        before do
          Karafka.env.stubs(:production?).returns(true)
          get "topics/#{topic}/replication"
        end

        it "displays the no redundancy warning with production severity" do
          assert(response.ok?)
          assert_body("No Replication Redundancy")
          assert_body("replication factor of")
          assert_body("redundant copies")
          assert_body("permanently lost")
          assert_body("Broker Failures and Fault Tolerance")
          assert_body("critical issue")
        end

        it "shows fault tolerance as 0 brokers" do
          assert_body("0 brokers")
        end
      end

      context "when not in production environment" do
        before do
          Karafka.env.stubs(:production?).returns(false)
          get "topics/#{topic}/replication"
        end

        it "displays the no redundancy warning with development context" do
          assert(response.ok?)
          assert_body("No Replication Redundancy")
          assert_body("replication factor of")
          assert_body("acceptable for development")
          assert_body("can cause data loss in production")
        end

        it "still displays the replication settings cards" do
          assert_body("Replication Factor")
          assert_body("Min In-Sync Replicas")
          assert_body("Fault Tolerance")
        end
      end
    end

    context "when replication factor equals min.insync.replicas (zero fault tolerance)" do
      let(:partitions_data) { [{ replica_count: 2, leader: 1, in_sync_replica_brokers: "1,2" }] }

      let(:mock_synonym) do
        stub(name: "default.replication.factor",
          value: "2",
          default?: false,
          read_only?: false,
          sensitive?: false,
          synonym?: true,
          synonyms: [])
      end

      let(:mock_config) do
        stub(name: "min.insync.replicas",
          value: "2",
          default?: false,
          read_only?: false,
          sensitive?: false,
          synonym?: false,
          synonyms: [mock_synonym])
      end

      let(:topic_model) do
        Karafka::Web::Ui::Models::Topic.new(
          topic_name: topic,
          partition_count: 2,
          partitions: partitions_data
        )
      end

      let(:distribution_result) do
        [
          Karafka::Web::Ui::Lib::HashProxy.new(std_dev: 0, std_dev_rel: 0.0, sum: 0),
          [Karafka::Web::Ui::Lib::HashProxy.new(count: 0, partition_id: 0, share: 0.0, diff: 0)]
        ]
      end

      before do
        topic_model.stubs(:configs).returns([mock_config])
        topic_model.stubs(:distribution).returns(distribution_result)
        stub_and_passthrough(Karafka::Web::Ui::Models::Topic, :find)
        Karafka::Web::Ui::Models::Topic.stubs(:find).with(topic).returns(topic_model)
        Karafka::Admin.stubs(:read_watermark_offsets).returns([0, 100])
        Karafka.env.stubs(:production?).returns(true)

        get "topics/#{topic}/replication"
      end

      it "displays the zero fault tolerance warning" do
        assert(response.ok?)
        assert_body("Replication Resilience Issue Detected")
        assert_body("zero")
        assert_body("fault tolerance")
        assert_body("replication factor of")
        assert_body("one")
      end

      it "shows fault tolerance as 0 brokers" do
        assert_body("0 brokers")
      end
    end

    context "when min.insync.replicas is 1 with higher replication factor (low durability)" do
      let(:partitions_data) { [{ replica_count: 3, leader: 1, in_sync_replica_brokers: "1,2,3" }] }

      let(:mock_synonym) do
        stub(name: "default.replication.factor",
          value: "3",
          default?: false,
          read_only?: false,
          sensitive?: false,
          synonym?: true,
          synonyms: [])
      end

      let(:mock_config) do
        stub(name: "min.insync.replicas",
          value: "1",
          default?: false,
          read_only?: false,
          sensitive?: false,
          synonym?: false,
          synonyms: [mock_synonym])
      end

      let(:topic_model) do
        Karafka::Web::Ui::Models::Topic.new(
          topic_name: topic,
          partition_count: 2,
          partitions: partitions_data
        )
      end

      let(:distribution_result) do
        [
          Karafka::Web::Ui::Lib::HashProxy.new(std_dev: 0, std_dev_rel: 0.0, sum: 0),
          [Karafka::Web::Ui::Lib::HashProxy.new(count: 0, partition_id: 0, share: 0.0, diff: 0)]
        ]
      end

      before do
        topic_model.stubs(:configs).returns([mock_config])
        topic_model.stubs(:distribution).returns(distribution_result)
        stub_and_passthrough(Karafka::Web::Ui::Models::Topic, :find)
        Karafka::Web::Ui::Models::Topic.stubs(:find).with(topic).returns(topic_model)
        Karafka::Admin.stubs(:read_watermark_offsets).returns([0, 100])
        Karafka.env.stubs(:production?).returns(true)
        get "topics/#{topic}/replication"
      end

      it "displays the low durability warning" do
        assert(response.ok?)
        assert_body("Low Data Durability Configuration")
        assert_body("min.insync.replicas")
        assert_body("replication factor of")
        assert_body("replication to followers completes")
        assert_body("permanently")
      end

      it "shows positive fault tolerance" do
        assert_body("2 broker(s)")
      end
    end

    context "when configuration is healthy (RF > minISR and minISR > 1)" do
      let(:partitions_data) { [{ replica_count: 3, leader: 1, in_sync_replica_brokers: "1,2,3" }] }

      let(:mock_synonym) do
        stub(name: "default.replication.factor",
          value: "3",
          default?: false,
          read_only?: false,
          sensitive?: false,
          synonym?: true,
          synonyms: [])
      end

      let(:mock_config) do
        stub(name: "min.insync.replicas",
          value: "2",
          default?: false,
          read_only?: false,
          sensitive?: false,
          synonym?: false,
          synonyms: [mock_synonym])
      end

      let(:topic_model) do
        Karafka::Web::Ui::Models::Topic.new(
          topic_name: topic,
          partition_count: 2,
          partitions: partitions_data
        )
      end

      let(:distribution_result) do
        [
          Karafka::Web::Ui::Lib::HashProxy.new(std_dev: 0, std_dev_rel: 0.0, sum: 0),
          [Karafka::Web::Ui::Lib::HashProxy.new(count: 0, partition_id: 0, share: 0.0, diff: 0)]
        ]
      end

      before do
        topic_model.stubs(:configs).returns([mock_config])
        topic_model.stubs(:distribution).returns(distribution_result)
        stub_and_passthrough(Karafka::Web::Ui::Models::Topic, :find)
        Karafka::Web::Ui::Models::Topic.stubs(:find).with(topic).returns(topic_model)
        Karafka::Admin.stubs(:read_watermark_offsets).returns([0, 100])
        get "topics/#{topic}/replication"
      end

      it "displays the success message" do
        assert(response.ok?)
        assert_body("Replication Configuration is Fault Tolerant")
        assert_body("broker failure")
      end

      it "shows positive fault tolerance" do
        assert_body("1 broker(s)")
      end
    end
  end
end
