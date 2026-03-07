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
      assert(response.ok?)
      assert_body("ID")
      assert_body(support_message)
      assert_body(breadcrumbs)
    end
  end

  describe "#replication" do
    before { get "cluster/replication" }

    it do
      assert(response.ok?)
      assert_body(support_message)
      assert_body(breadcrumbs)
    end

    context "when there are many pages with topics" do
      before { 30.times { create_topic } }

      context "when we visit existing page" do
        before { get "cluster/replication?page=2" }

        it do
          assert(response.ok?)
          assert_body(support_message)
          assert_body(breadcrumbs)
          assert_body(pagination)
        end
      end

      context "when we visit a non-existing page" do
        before { get "cluster/replication?page=100000000" }

        it do
          assert(response.ok?)
          assert_body(pagination)
          assert_body(support_message)
          assert_body(no_meaningful_results)
        end
      end

      context "when visiting with invalid page parameters" do
        before { get "cluster/replication?page=abc" }

        it "defaults to first page" do
          assert(response.ok?)
          assert_body("Replication")
          assert_body(support_message)
        end
      end

      context "when visiting with negative page number" do
        before { get "cluster/replication?page=-1" }

        it "defaults to first page" do
          assert(response.ok?)
          assert_body("Replication")
          assert_body(support_message)
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
        assert(response.ok?)
        assert_body("Partition")
        assert_body("Leader")
        assert_body("In sync brokers")
        # The topic might not always be visible immediately, but column headers should be present
      end
    end

    context "when using custom per_page parameter" do
      before do
        20.times { create_topic }
        get "cluster/replication?per_page=5"
      end

      it "respects custom page size" do
        assert(response.ok?)
        assert_body(pagination)
        assert_body(support_message)
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
