# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { refute(described_class.independent?) }
    it { assert_equal(:initial_consumers_state, described_class.dependency) }
    it { assert_equal({ issue_type: :presence }, described_class.halted_details) }
  end

  describe "#call" do
    context "when consumers metrics is present and valid" do
      let(:metrics) { { aggregated: {} } }

      before do
        allow(Karafka::Web::Ui::Models::ConsumersMetrics).to receive(:current).and_return(metrics)
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert_equal(:presence, result.details[:issue_type])
      end

      it "caches the metrics in context" do
        check.call

        assert_equal(metrics, context.current_metrics)
      end
    end

    context "when consumers metrics is not present" do
      before do
        allow(Karafka::Web::Ui::Models::ConsumersMetrics).to receive(:current).and_return(nil)
      end

      it "returns failure" do
        result = check.call

        assert_equal(:failure, result.status)
        assert_equal(:presence, result.details[:issue_type])
      end
    end

    context "when consumers metrics is corrupted (JSON parse error)" do
      before do
        allow(Karafka::Web::Ui::Models::ConsumersMetrics)
          .to receive(:current)
          .and_raise(JSON::ParserError)
      end

      it "returns failure with deserialization issue type" do
        result = check.call

        assert_equal(:failure, result.status)
        assert_equal(:deserialization, result.details[:issue_type])
      end
    end

    context "when metrics is already cached in context" do
      let(:metrics) { { aggregated: {} } }

      before do
        context.current_metrics = metrics
        allow(Karafka::Web::Ui::Models::ConsumersMetrics).to receive(:current)
      end

      it "does not fetch again" do
        check.call

        expect(Karafka::Web::Ui::Models::ConsumersMetrics).not_to have_received(:current)
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
      end
    end
  end
end
