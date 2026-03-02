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
end
