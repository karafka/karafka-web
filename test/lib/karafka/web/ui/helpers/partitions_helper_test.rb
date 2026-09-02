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

      it "appends the replica count as subtext" do
        assert_includes(result, "3 replicas")
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

      it "appends the in-sync count as subtext" do
        assert_includes(result, "2 in-sync")
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

    context "when the isrs array is empty (fully under-replicated partition)" do
      let(:partition) { { leader: 1, in_sync_replica_brokers: 0, replicas: [1], isrs: [] } }

      it "renders a muted placeholder" do
        assert_includes(result, "&mdash;")
      end
    end
  end

  # Default config.ui.health.lags.high_threshold is 10_000 (warning at half: 5_000)
  describe "#lag_severity" do
    it { assert_nil(lag_severity(-1)) }
    it { assert_nil(lag_severity(0)) }
    it { assert_nil(lag_severity(4_999)) }
    it { assert_equal(:warning, lag_severity(5_000)) }
    it { assert_equal(:warning, lag_severity(9_999)) }
    it { assert_equal(:error, lag_severity(10_000)) }
    it { assert_equal(:error, lag_severity(1_000_000)) }
  end

  describe "#lag_status_row" do
    it { assert_equal("status-row-error", lag_status_row(10_000)) }
    it { assert_equal("status-row-warning", lag_status_row(5_000)) }
    it { assert_equal("", lag_status_row(100)) }

    context "with a fallback" do
      it "uses the fallback when the lag is not high" do
        assert_equal("status-row-running", lag_status_row(100, "status-row-running"))
      end

      it "lets a high lag win over the fallback" do
        assert_equal("status-row-error", lag_status_row(10_000, "status-row-running"))
      end
    end
  end

  describe "#topic_lag_status_row" do
    def topic_stub(avg_lag:, skewed:)
      obj = Object.new
      obj.define_singleton_method(:avg_lag) { avg_lag }
      obj.define_singleton_method(:skewed?) { skewed }
      obj
    end

    it "flags high average lag as an error" do
      assert_equal("status-row-error", topic_lag_status_row(topic_stub(avg_lag: 10_000, skewed: false)))
    end

    it "flags medium average lag as a warning" do
      assert_equal("status-row-warning", topic_lag_status_row(topic_stub(avg_lag: 5_000, skewed: false)))
    end

    it "flags a skewed topic as a warning even when the average lag is low" do
      assert_equal("status-row-warning", topic_lag_status_row(topic_stub(avg_lag: 10, skewed: true)))
    end

    it "keeps error precedence over a skew warning" do
      assert_equal("status-row-error", topic_lag_status_row(topic_stub(avg_lag: 10_000, skewed: true)))
    end

    it "returns no class for a healthy topic" do
      assert_equal("", topic_lag_status_row(topic_stub(avg_lag: 10, skewed: false)))
    end
  end
end
