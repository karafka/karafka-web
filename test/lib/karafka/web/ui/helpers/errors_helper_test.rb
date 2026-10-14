# frozen_string_literal: true

describe_current do
  let(:helper) do
    Class.new do
      include Karafka::Web::Ui::Helpers::TailwindHelper
      include Karafka::Web::Ui::Helpers::ErrorsHelper
    end.new
  end

  let(:valid_payload) { { schema_version: "1.2.0", error_class: "StandardError" } }

  # Builds a message-like double whose `#payload` returns the given value
  def msg_double(payload)
    obj = Object.new
    obj.define_singleton_method(:payload) { payload }
    obj
  end

  describe "#displayable_error" do
    it "returns the payload for one of our error reports (has a schema_version)" do
      assert_equal(valid_payload, helper.displayable_error(msg_double(valid_payload)))
    end

    it "returns false for a compacted-offset marker (array)" do
      refute(helper.displayable_error([0]))
    end

    it "returns false when JSON deserialization fails" do
      obj = Object.new
      obj.define_singleton_method(:payload) { raise(JSON::ParserError, "bad") }

      refute(helper.displayable_error(obj))
    end

    it "returns false when zlib inflation fails" do
      obj = Object.new
      obj.define_singleton_method(:payload) { raise(Zlib::DataError, "corrupt") }

      refute(helper.displayable_error(obj))
    end

    it "re-raises unexpected errors instead of swallowing real bugs" do
      obj = Object.new
      obj.define_singleton_method(:payload) { raise(NoMethodError, "boom") }

      assert_raises(NoMethodError) { helper.displayable_error(obj) }
    end

    it "returns false when the payload is not a hash" do
      refute(helper.displayable_error(msg_double("just a string")))
    end

    it "returns false for a foreign hash without a schema_version" do
      refute(helper.displayable_error(msg_double({ a: "1" })))
    end
  end

  describe "#delivery_status_badge" do
    it "renders a success badge for a persisted message" do
      assert_equal(
        '<span class="badge  badge-success">persisted</span>',
        helper.delivery_status_badge("persisted")
      )
    end

    it "renders a warning badge for a possibly persisted message" do
      assert_equal(
        '<span class="badge  badge-warning">possibly persisted</span>',
        helper.delivery_status_badge("possibly persisted")
      )
    end

    it "renders an error badge for a message that was not persisted" do
      assert_equal(
        '<span class="badge  badge-error">not persisted</span>',
        helper.delivery_status_badge("not persisted")
      )
    end

    it "returns nil for an unknown status" do
      assert_nil(helper.delivery_status_badge("<b>x</b>"))
      assert_nil(helper.delivery_status_badge(nil))
    end
  end
end
