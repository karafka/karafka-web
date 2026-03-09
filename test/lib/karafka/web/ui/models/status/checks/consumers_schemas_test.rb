# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { refute(described_class.independent?) }
    it { assert_equal(:consumers_reports, described_class.dependency) }
    it { assert_equal({ incompatible: [] }, described_class.halted_details) }
  end

  describe "#call" do
    context "when all processes have compatible schemas" do
      let(:process1) do
        stub(schema_compatible?: true)
      end

      let(:process2) do
        stub(schema_compatible?: true)
      end

      before do
        context.processes = [process1, process2]
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert_empty(result.details[:incompatible])
      end
    end

    context "when some processes have incompatible schemas" do
      let(:compatible_process) do
        stub(schema_compatible?: true)
      end

      let(:incompatible_process) do
        stub(schema_compatible?: false)
      end

      before do
        context.processes = [compatible_process, incompatible_process]
      end

      it "returns warning" do
        result = check.call

        assert_equal(:warning, result.status)
        assert(result.success?)
      end

      it "includes incompatible processes in details" do
        result = check.call

        assert_equal([incompatible_process], result.details[:incompatible])
      end
    end

    context "when all processes have incompatible schemas" do
      let(:incompatible1) do
        stub(schema_compatible?: false)
      end

      let(:incompatible2) do
        stub(schema_compatible?: false)
      end

      before do
        context.processes = [incompatible1, incompatible2]
      end

      it "returns warning with all incompatible processes" do
        result = check.call

        assert_equal(:warning, result.status)
        assert_equal(2, result.details[:incompatible].size)
        assert_includes(result.details[:incompatible], incompatible1)
        assert_includes(result.details[:incompatible], incompatible2)
      end
    end
  end
end
