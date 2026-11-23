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

  describe "#backtrace_frame_class" do
    let(:muted) { "text-base-content/60" }
    let(:marked) { "font-bold" }

    it "marks frames of the application" do
      assert_equal(marked, helper.backtrace_frame_class("app/consumers/orders_consumer.rb:7:in 'consume'"))
      assert_equal(marked, helper.backtrace_frame_class("karafka.rb:7:in 'block in <top (required)>'"))
      assert_equal(marked, helper.backtrace_frame_class("/srv/app/lib/orders.rb:3:in 'call'"))
    end

    it "mutes gem frames with the gem home stripped" do
      assert_equal(muted, helper.backtrace_frame_class("gems/karafka-2.5.0/lib/karafka/runner.rb:36:in 'call'"))
      assert_equal(muted, helper.backtrace_frame_class("karafka-2.5.0/lib/karafka/runner.rb:36:in 'call'"))
      assert_equal(muted, helper.backtrace_frame_class("rdkafka-0.20.0-x86_64-linux-gnu/lib/rdkafka.rb:1"))
    end

    it "mutes gem frames installed in the application or kept with absolute paths" do
      assert_equal(muted, helper.backtrace_frame_class("vendor/bundle/ruby/3.4.0/gems/karafka-2.5.0/lib/a.rb:1"))
      assert_equal(muted, helper.backtrace_frame_class("/usr/local/bundle/gems/karafka-2.5.0/lib/a.rb:1"))
    end

    it "mutes Ruby frames" do
      assert_equal(muted, helper.backtrace_frame_class("<internal:thread_sync>:18:in 'pop'"))
      assert_equal(muted, helper.backtrace_frame_class("/usr/local/lib/ruby/3.4.0/monitor.rb:201:in 'synchronize'"))
    end
  end
end
