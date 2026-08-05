# frozen_string_literal: true

describe_current do
  include described_class

  describe "#status_badge" do
    let(:result) { status_badge(status) }

    context "when status is initialized, supervising, or running" do
      %w[
        initialized
        supervising
        running
      ].each do |valid_status|
        let(:status) { valid_status }

        it "returns badge-success" do
          assert_equal("badge-success", result)
        end
      end
    end

    context "when status is quieting" do
      let(:status) { "quieting" }

      it "returns badge-warning" do
        assert_equal("badge-warning", result)
      end
    end

    context "when status is quiet or stopping" do
      %w[
        quiet
        stopping
      ].each do |warning_status|
        let(:status) { warning_status }

        it "returns badge-warning" do
          assert_equal("badge-warning", result)
        end
      end
    end

    context "when status is stopped or terminated" do
      %w[
        stopped
        terminated
      ].each do |danger_status|
        let(:status) { danger_status }

        it "returns badge-error" do
          assert_equal("badge-error", result)
        end
      end
    end

    context "when status is unsupported" do
      let(:status) { "unsupported_status" }

      it "raises an UnsupportedCaseError" do
        assert_raises(Karafka::Errors::UnsupportedCaseError) { result }
      end
    end
  end

  describe "#lag_trend_badge" do
    let(:result) { lag_trend_badge(trend) }

    context "when trend is negative" do
      let(:trend) { -1 }

      it "returns badge-success" do
        assert_equal("badge-success", result)
      end
    end

    context "when trend is positive" do
      let(:trend) { 1 }

      it "returns badge-warning" do
        assert_equal("badge-warning", result)
      end
    end

    context "when trend is zero" do
      let(:trend) { 0 }

      it "returns badge-secondary" do
        assert_equal("badge-secondary", result)
      end
    end
  end

  describe "#kafka_state_badge" do
    let(:result) { kafka_state_badge(state) }

    context "when state is up, active, or steady" do
      %w[
        up
        active
        steady
      ].each do |positive_state|
        let(:state) { positive_state }

        it "returns badge-success" do
          assert_equal("badge-success", result)
        end
      end
    end

    context "when state is any other value" do
      let(:state) { "down" }

      it "returns badge-warning" do
        assert_equal("badge-warning", result)
      end
    end
  end

  describe "#format_memory" do
    let(:result) { format_memory(mem_kb) }

    context "when mem_kb is nil or zero" do
      let(:mem_kb) { nil }

      it "returns 0" do
        assert_equal("0", result)
      end
    end

    context "when mem_kb is less than 10,240" do
      let(:mem_kb) { 1023 }

      it "returns the memory in KB" do
        assert_equal("1,023 KB", result)
      end
    end

    context "when mem_kb is between 10,240 and 1,000,000" do
      let(:mem_kb) { 10_240 }

      it "returns the memory in MB" do
        assert_equal("10 MB", result)
      end
    end

    context "when mem_kb is greater than or equal to 1,000,000" do
      let(:mem_kb) { 1_048_576 } # 1024 * 1024

      it "returns the memory in GB" do
        assert_equal("1.0 GB", result)
      end
    end
  end

  describe "#number_with_delimiter" do
    let(:result) { number_with_delimiter(number, delimiter) }

    let(:delimiter) { "," }

    context "when number is nil" do
      let(:number) { nil }

      it "returns an empty string" do
        assert_equal("", result)
      end
    end

    context "when number is an integer" do
      let(:number) { 1000 }

      it "formats the number with commas" do
        assert_equal("1,000", result)
      end
    end

    context "when number is a float" do
      let(:number) { 1000.75 }

      it "formats the number with commas and preserves decimal part" do
        assert_equal("1,000.75", result)
      end
    end

    context "with a custom delimiter" do
      let(:number) { 1000 }
      let(:delimiter) { "." }

      it "formats the number with the custom delimiter" do
        assert_equal("1.000", result)
      end
    end
  end

  describe "#truncate" do
    let(:string) { "This is a long string that we will use to test the truncate method." }

    context "when the string is shorter than the specified length" do
      let(:length) { 100 }

      it "returns the original string" do
        assert_equal(string, truncate(string, length: length))
      end
    end

    context "when using the default strategy" do
      let(:length) { 20 }
      let(:expected_result) { "This is a long st..." }

      it "truncates the string to the specified length with omission at the end" do
        assert_includes(truncate(string, length: length), expected_result)
      end
    end

    context "when using the middle strategy" do
      let(:length) { 20 }
      let(:expected_result) { "This is ... method." }

      it "truncates the string to the specified length with omission in the middle" do
        assert_includes(truncate(string, length: length, strategy: :middle), expected_result)
      end
    end

    context "when an unsupported strategy is provided" do
      let(:expected_error) { Karafka::Errors::UnsupportedCaseError }

      it "raises an UnsupportedCaseError" do
        assert_raises(expected_error) { truncate(string, strategy: :unknown) }
      end
    end
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
