# frozen_string_literal: true

describe_current do
  let(:ui_kafka) { Karafka::Web.config.ui.kafka }

  describe ".defaults" do
    it "expect to return the Web UI kafka settings" do
      assert_equal ui_kafka, described_class.defaults
    end
  end

  describe ".call" do
    it "expect to inject the Web UI defaults into an empty settings hash" do
      assert_equal ui_kafka, described_class.call({})
    end

    it "expect not to overwrite a setting the caller provided" do
      key = ui_kafka.keys.first

      result = described_class.call(key => "caller-value")

      assert_equal "caller-value", result[key]
    end

    it "expect to fill in the defaults the caller did not provide" do
      result = described_class.call({ "some.extra.setting": 1 })

      ui_kafka.each do |key, value|
        assert_equal value, result[key]
      end

      assert_equal 1, result[:"some.extra.setting"]
    end

    it "expect to return the mutated target hash" do
      target = {}

      assert_same target, described_class.call(target)
    end

    it "expect not to mutate the Web UI kafka config" do
      before = ui_kafka.dup

      described_class.call({ "a.b.c": 1 })

      assert_equal before, ui_kafka
    end
  end
end
