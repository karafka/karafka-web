# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { assert(described_class.independent?) }
    it { assert_nil(described_class.dependency) }
  end

  describe "#call" do
    context "when web ui group is in routes" do
      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert(result.success?)
        assert_equal({}, result.details)
      end
    end

    context "when web ui group is not in routes" do
      before do
        allow(Karafka::Web.config).to receive(:group_id).and_return("non_existent_group")
      end

      it "returns failure" do
        result = check.call

        assert_equal(:failure, result.status)
        refute(result.success?)
        assert_equal({}, result.details)
      end
    end
  end
end
