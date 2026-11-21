# frozen_string_literal: true

describe_current do
  let(:ui) { Karafka::Web.config.ui }

  describe "ui.dlq_patterns" do
    let(:original_patterns) { ui.dead_letter_queue_patterns }

    before { original_patterns }

    after { ui.dead_letter_queue_patterns = original_patterns }

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
