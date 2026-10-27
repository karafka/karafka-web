# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { refute(described_class.independent?) }
    it { assert_equal(:consumers_reports_schema_state, described_class.dependency) }
    it { assert_equal({ rejected: [] }, described_class.halted_details) }
  end

  describe "#call" do
    context "when the state has no rejected reports key" do
      before { context.current_state = { schema_state: "compatible" } }

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert_equal({ rejected: [] }, result.details)
      end
    end

    context "when no reports were rejected" do
      before { context.current_state = { rejected_reports: [] } }

      it { assert_equal(:success, check.call.status) }
    end

    context "when reports were rejected" do
      let(:rejection) do
        {
          process_id: "shinra:1:1",
          offset: 7,
          errors: { "process.status": "needs to be present" },
          rejected_at: Time.now.to_f
        }
      end

      before { context.current_state = { rejected_reports: [rejection] } }

      it "returns a warning with the rejections" do
        result = check.call

        assert_equal(:warning, result.status)
        assert_equal([rejection], result.details[:rejected])
      end
    end
  end
end
