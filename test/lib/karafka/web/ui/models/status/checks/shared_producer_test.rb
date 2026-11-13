# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }
  let(:producer) { stub(idempotent?: false, transactional?: false) }

  before { Karafka.stubs(:producer).returns(producer) }

  describe "DSL configuration" do
    it { assert(described_class.independent?) }
    it { assert_nil(described_class.dependency) }
  end

  describe "#call" do
    context "when the default Web UI producer wraps a regular producer" do
      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert_equal({}, result.details)
      end
    end

    context "when the default Web UI producer wraps an idempotent producer" do
      before { producer.stubs(:idempotent?).returns(true) }

      it "returns info" do
        result = check.call

        assert_equal(:info, result.status)
        assert_equal({ type: "idempotent" }, result.details)
        assert(result.success?)
      end
    end

    context "when the default Web UI producer wraps a transactional producer" do
      before { producer.stubs(:transactional?).returns(true) }

      it "returns info" do
        result = check.call

        assert_equal(:info, result.status)
        assert_equal({ type: "transactional" }, result.details)
        assert(result.success?)
      end
    end

    context "when a custom Web UI producer is configured" do
      before do
        producer.stubs(:idempotent?).returns(true)
        producer.stubs(:transactional?).returns(true)
        Karafka::Web.config.stubs(:producer).returns(PRODUCERS.regular)
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert_equal({}, result.details)
      end
    end
  end
end
