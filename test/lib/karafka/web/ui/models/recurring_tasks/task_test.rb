# frozen_string_literal: true

describe_current do
  let(:task) { described_class.new(attrs) }

  let(:attrs) { { enabled: true } }

  it { assert(task.class < Karafka::Web::Ui::Lib::HashProxy) }

  describe "#enabled?" do
    context "when enabled" do
      it { assert(task.enabled?) }
    end

    context "when disabled" do
      let(:attrs) { { enabled: false } }

      it { refute(task.enabled?) }
    end
  end
end
