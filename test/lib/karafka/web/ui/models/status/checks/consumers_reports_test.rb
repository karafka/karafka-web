# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }
  let(:current_state) { { dispatched_at: Time.now.to_f } }

  describe "DSL configuration" do
    it { refute(described_class.independent?) }
    it { assert_equal(:initial_consumers_metrics, described_class.dependency) }
    it { assert_equal({}, described_class.halted_details) }
  end

  describe "#call" do
    before do
      context.current_state = current_state
    end

    context "when processes can be loaded successfully" do
      let(:process) { Karafka::Web::Ui::Models::Process.new(Fixtures.consumers_reports_json) }
      let(:processes) { [process] }

      before do
        allow(Karafka::Web::Ui::Models::Processes)
          .to receive(:all)
          .with(current_state)
          .and_return(processes)
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert_equal({}, result.details)
      end

      it "caches processes in context" do
        check.call

        assert_equal(processes, context.processes)
      end
    end

    context "when processes data is corrupted (JSON parse error)" do
      before do
        allow(Karafka::Web::Ui::Models::Processes)
          .to receive(:all)
          .and_raise(JSON::ParserError)
      end

      it "returns failure" do
        result = check.call

        assert_equal(:failure, result.status)
        assert_equal({}, result.details)
      end
    end

    context "when processes are already cached in context" do
      let(:process) { Karafka::Web::Ui::Models::Process.new(Fixtures.consumers_reports_json) }
      let(:processes) { [process] }

      before do
        context.processes = processes
        allow(Karafka::Web::Ui::Models::Processes).to receive(:all)
      end

      it "does not fetch again" do
        check.call

        expect(Karafka::Web::Ui::Models::Processes).not_to have_received(:all)
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
      end
    end
  end
end
