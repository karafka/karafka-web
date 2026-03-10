# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { refute(described_class.independent?) }
    it { assert_equal(:replication, described_class.dependency) }
    it { assert_equal({ issue_type: :presence }, described_class.halted_details) }
  end

  describe "#call" do
    context "when consumers state is present and valid" do
      let(:state) { { dispatched_at: Time.now.to_f, schema_state: "compatible" } }

      before do
        Karafka::Web::Ui::Models::ConsumersState.stubs(:current).returns(state)
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert_equal(:presence, result.details[:issue_type])
      end

      it "caches the state in context" do
        check.call

        assert_equal(state, context.current_state)
      end
    end

    context "when consumers state is not present" do
      before do
        Karafka::Web::Ui::Models::ConsumersState.stubs(:current).returns(nil)
      end

      it "returns failure" do
        result = check.call

        assert_equal(:failure, result.status)
        assert_equal(:presence, result.details[:issue_type])
      end
    end

    context "when consumers state is corrupted (JSON parse error)" do
      before do
        Karafka::Web::Ui::Models::ConsumersState.stubs(:current).raises(JSON::ParserError)
      end

      it "returns failure with deserialization issue type" do
        result = check.call

        assert_equal(:failure, result.status)
        assert_equal(:deserialization, result.details[:issue_type])
      end
    end

    context "when state is already cached in context" do
      let(:state) { { dispatched_at: Time.now.to_f } }

      before do
        context.current_state = state
        Karafka::Web::Ui::Models::ConsumersState.stubs(:current)
      end

      it "does not fetch again" do
        Karafka::Web::Ui::Models::ConsumersState.expects(:current).never
        check.call
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
      end
    end
  end
end
