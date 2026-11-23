# frozen_string_literal: true

describe_current do
  let(:helper) { Class.new { include Karafka::Web::Ui::Helpers::ErrorsHelper }.new }

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

  describe "#error_message_preview" do
    it "returns a message of 200 characters escaped and not cut" do
      message = "<b>#{"x" * 193}</b>"

      assert_equal(Rack::Utils.escape_html(message), helper.error_message_preview(message))
    end

    it "cuts a longer message with an ellipsis and puts the escaped full message in the title" do
      message = "#{"x" * 200}<b>tail</b>"

      assert_equal(
        %(<span title="#{"x" * 200}&lt;b&gt;tail&lt;/b&gt;">#{"x" * 200}…</span>),
        helper.error_message_preview(message)
      )
    end

    it "escapes the cut part of the message" do
      message = "#{"x" * 197}<b>tail</b>"

      assert_includes(helper.error_message_preview(message), ">#{"x" * 197}&lt;b&gt;…</span>")
    end
  end

  describe "#delivery_status_name" do
    it "names a persisted message" do
      assert_equal(
        "persisted",
        helper.delivery_status_name(Rdkafka::Bindings::RD_KAFKA_MSG_STATUS_PERSISTED)
      )
    end

    it "names a possibly persisted message" do
      assert_equal(
        "possibly persisted",
        helper.delivery_status_name(Rdkafka::Bindings::RD_KAFKA_MSG_STATUS_POSSIBLY_PERSISTED)
      )
    end

    it "names a message that was not persisted" do
      assert_equal(
        "not persisted",
        helper.delivery_status_name(Rdkafka::Bindings::RD_KAFKA_MSG_STATUS_NOT_PERSISTED)
      )
    end

    it "returns an unknown status as is" do
      assert_equal("99", helper.delivery_status_name(99))
    end
  end
end
