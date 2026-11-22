# frozen_string_literal: true

describe_current do
  let(:ui) { Karafka::Web.config.ui }
  let(:original_patterns) { ui.dead_letter_queue_patterns }

  before { original_patterns }

  after { ui.dead_letter_queue_patterns = original_patterns }

  describe "ui.dlq_patterns" do
    it "reads the dead_letter_queue_patterns value with a deprecation warning" do
      ui.dead_letter_queue_patterns = [/custom/]
      ui.expects(:warn).with(regexp_matches(/config.ui.dlq_patterns is deprecated/))

      assert_equal([/custom/], ui.dlq_patterns)
    end

    it "sets the dead_letter_queue_patterns value with a deprecation warning" do
      ui.expects(:warn).with(regexp_matches(/config.ui.dlq_patterns= is deprecated/))
      ui.dlq_patterns = [/legacy/]

      assert_equal([/legacy/], ui.dead_letter_queue_patterns)
      assert_equal([/legacy/], Karafka::Web.config.to_h[:ui][:dead_letter_queue_patterns])
    end
  end

  describe "ui.dead_letter_queue_patterns" do
    it "reads and sets the value without a deprecation warning" do
      ui.expects(:warn).never
      ui.dead_letter_queue_patterns = [/custom/]

      assert_equal([/custom/], ui.dead_letter_queue_patterns)
    end
  end
end
