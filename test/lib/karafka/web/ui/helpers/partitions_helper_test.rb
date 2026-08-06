# frozen_string_literal: true

describe_current do
  include described_class

  # `link: true` badges use PathsHelper#root_path (mixed into the app at runtime); stub it here
  def root_path(*args)
    "/karafka/#{args.join("/")}"
  end

  describe "#partition_replica_brokers" do
    let(:result) { partition_replica_brokers(partition) }

    context "when the broker id arrays are available (karafka-rdkafka >= 0.28.0)" do
      let(:partition) do
        {
          leader: 1,
          replica_count: 3,
          in_sync_replica_brokers: 2,
          replicas: [1, 2, 3],
          isrs: [1, 2]
        }
      end

      it "emphasizes the leader" do
        assert_includes(result, '<span class="badge badge-primary">1</span>')
      end

      it "renders in-sync replicas as info badges" do
        assert_includes(result, '<span class="badge badge-info">2</span>')
      end

      it "highlights out-of-sync replicas as a warning" do
        assert_includes(result, '<span class="badge badge-warning">3</span>')
      end

      it "does not link the badges by default" do
        refute_includes(result, "<a ")
      end

      context "when link: true is passed (Pro broker details available)" do
        let(:result) { partition_replica_brokers(partition, link: true) }

        it "links each broker badge to its broker details page" do
          assert_includes(
            result,
            '<a href="/karafka/cluster/1" title="Broker 1 details">' \
            '<span class="badge badge-primary">1</span></a>'
          )
          assert_includes(result, '<a href="/karafka/cluster/3" title="Broker 3 details">')
        end
      end
    end

    context "when the replicas array is empty" do
      let(:partition) { { leader: 1, replica_count: 0, replicas: [], isrs: [] } }

      it "renders a muted placeholder" do
        assert_includes(result, "&mdash;")
      end
    end

    context "when the broker id arrays are unavailable (older karafka-rdkafka)" do
      let(:partition) { { leader: 1, replica_count: 3, in_sync_replica_brokers: 2 } }

      it "falls back to the numeric replica count" do
        assert_equal("3", result)
      end
    end
  end

  describe "#partition_in_sync_brokers" do
    let(:result) { partition_in_sync_brokers(partition) }

    context "when the broker id arrays are available (karafka-rdkafka >= 0.28.0)" do
      let(:partition) do
        {
          leader: 1,
          replica_count: 3,
          in_sync_replica_brokers: 2,
          replicas: [1, 2, 3],
          isrs: [1, 2]
        }
      end

      it "emphasizes the leader" do
        assert_includes(result, '<span class="badge badge-primary">1</span>')
      end

      it "renders the other in-sync brokers as success badges" do
        assert_includes(result, '<span class="badge badge-success">2</span>')
      end

      it "does not render out-of-sync brokers" do
        refute_includes(result, ">3</span>")
      end

      it "does not link the badges by default" do
        refute_includes(result, "<a ")
      end

      context "when link: true is passed (Pro broker details available)" do
        let(:result) { partition_in_sync_brokers(partition, link: true) }

        it "links each in-sync broker badge to its broker details page" do
          assert_includes(
            result,
            '<a href="/karafka/cluster/2" title="Broker 2 details">' \
            '<span class="badge badge-success">2</span></a>'
          )
        end
      end
    end

    context "when the isrs array is empty" do
      let(:partition) { { leader: 1, in_sync_replica_brokers: 0, replicas: [], isrs: [] } }

      it "renders a muted placeholder" do
        assert_includes(result, "&mdash;")
      end
    end

    context "when the broker id arrays are unavailable (older karafka-rdkafka)" do
      let(:partition) { { leader: 1, replica_count: 3, in_sync_replica_brokers: 2 } }

      it "falls back to the numeric in-sync count" do
        assert_equal("2", result)
      end
    end
  end
end
