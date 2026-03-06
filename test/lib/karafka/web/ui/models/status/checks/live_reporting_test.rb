# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { refute(described_class.independent?) }
    it { assert_equal(:consumers_reports, described_class.dependency) }
    it { assert_equal({}, described_class.halted_details) }
  end

  describe "#call" do
    context "when there are active processes" do
      let(:process1) { instance_double(Karafka::Web::Ui::Models::Process) }
      let(:process2) { instance_double(Karafka::Web::Ui::Models::Process) }

      before do
        context.processes = [process1, process2]
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert(result.success?)
      end
    end

    context "when there are no processes" do
      before do
        context.processes = []
      end

      it "returns failure" do
        result = check.call

        assert_equal(:failure, result.status)
        refute(result.success?)
      end
    end
  end
end
