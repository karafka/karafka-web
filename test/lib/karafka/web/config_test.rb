# frozen_string_literal: true

describe_current do
  let(:ui) { Karafka::Web.config.ui }

  describe "ui.dead_letter_queue_patterns" do
    it { assert_equal([/(dlq)|(dead_letter)/i], described_class.new.config.ui.dead_letter_queue_patterns) }
  end

  describe "ui.dlq_patterns" do
    before { @previous = ui.dead_letter_queue_patterns }

    after { ui.dead_letter_queue_patterns = @previous }

    it "reads the dead_letter_queue_patterns value" do
      ui.dead_letter_queue_patterns = [/custom/]

      assert_equal([/custom/], ui.dlq_patterns)
    end

    it "sets the dead_letter_queue_patterns value" do
      ui.dlq_patterns = [/legacy/]

      assert_equal([/legacy/], ui.dead_letter_queue_patterns)
      assert_equal([/legacy/], Karafka::Web.config.to_h[:ui][:dead_letter_queue_patterns])
    end
  end
end
