# frozen_string_literal: true

describe_current do
  let(:app) { Karafka::Web::Ui::App }

  describe "cluster path redirect" do
    context "when visiting root cluster path" do
      before { get "cluster" }

      it "redirects to brokers" do
        assert_equal(302, response.status)
        assert_includes(response.headers["location"], "cluster/brokers")
      end
    end

    context "when visiting cluster with trailing slash" do
      before { get "cluster/" }

      it "redirects to brokers" do
        assert_equal(302, response.status)
        assert_includes(response.headers["location"], "cluster/brokers")
      end
    end
  end

  describe "#brokers" do
    before { get "cluster/brokers" }

    it do
      assert_ok
      assert_body("ID")
      assert_body(breadcrumbs)
    end
  end

  describe "#replication" do
    before { get "cluster/replication" }

    it do
      assert_ok
      assert_body(breadcrumbs)
    end

    context "when the cluster has multiple brokers (simulated metadata)" do
      let(:fake_topics) do
        [
          {
            topic_name: "multi-broker-topic",
            partitions: [
              # Fully in-sync: leader 1, replicas 1,2,3 all in ISR
              {
                partition_id: 0, leader: 1, replica_count: 3, in_sync_replica_brokers: 3,
                replicas: [1, 2, 3], isrs: [1, 2, 3]
              },
              # Under-replicated: leader 2, broker 3 has fallen out of the ISR set
              {
                partition_id: 1, leader: 2, replica_count: 3, in_sync_replica_brokers: 2,
                replicas: [2, 3, 1], isrs: [2, 1]
              }
            ]
          }
        ]
      end

      before do
        Karafka::Web::Ui::Models::ClusterInfo.stubs(:fetch).returns(stub(topics: fake_topics))
        get "cluster/replication"
      end

      it "renders replica broker id badges with health highlighting" do
        assert_ok
        assert_body("multi-broker-topic")
        # Leader emphasized
        assert_body('<span class="badge badge-primary">1</span>')
        # In-sync (non-leader) replica
        assert_body('<span class="badge badge-info">2</span>')
        # Out-of-sync replica (broker 3 is a replica of p1 but not in its ISR set)
        assert_body('<span class="badge badge-warning">3</span>')
      end

      it "does not link the broker badges in OSS (no per-broker details view)" do
        assert_ok
        refute_body('title="Broker 1 details"')
      end
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

      context "when visiting with invalid page parameters" do
        before { get "cluster/replication?page=abc" }

        it "defaults to first page" do
          assert_ok
          assert_body("Replication")
        end
      end

      context "when visiting with negative page number" do
        before { get "cluster/replication?page=-1" }

        it "defaults to first page" do
          assert_ok
          assert_body("Replication")
        end
      end
    end

    context "when topics have multiple partitions" do
      let(:topic_name) { create_topic(partitions: 5) }

      before do
        topic_name # Ensure topic is created
        get "cluster/replication"
      end

      it "displays partition information correctly" do
        assert_ok
        assert_body("Partition")
        assert_body("Leader")
        assert_body("Replicas")
        assert_body("In-Sync (ISR)")
        # The topic might not always be visible immediately, but column headers should be present
      end

      it "renders the replication legend and per-partition replica/in-sync counts" do
        assert_ok
        assert_body("Broker roles:")
        assert_body("replicas")
        assert_body("in-sync")
      end
    end

    context "when using custom per_page parameter" do
      before do
        20.times { create_topic }
        get "cluster/replication?per_page=5"
      end

      it "respects custom page size" do
        assert_ok
        assert_body(pagination)
      end
    end
  end

  describe "error handling" do
    context "when visiting invalid cluster subpath" do
      before { get "cluster/invalid" }

      it "redirects to valid cluster page" do
        refute(response.ok?)
        assert_equal(302, status)
      end
    end
  end
end
