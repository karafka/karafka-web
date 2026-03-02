# frozen_string_literal: true

describe_current do
  let(:task) { described_class.new(attrs) }

  let(:attrs) { { enabled: true } }

  it { assert_operator(task.class, :<, Karafka::Web::Ui::Lib::HashProxy) }

  describe "#enabled?" do
    context "when enabled" do
      it { assert_equal(true, task.enabled?) }
    end

    context "when disabled" do
      let(:attrs) { { enabled: false } }

      it { assert_equal(false, task.enabled?) }
    end
  end
end
