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

  describe "#backtrace_frame_muted?" do
    it "does not mute frames of the application" do
      refute(helper.backtrace_frame_muted?("app/consumers/orders_consumer.rb:7:in 'consume'"))
      refute(helper.backtrace_frame_muted?("karafka.rb:7:in 'block in <top (required)>'"))
      refute(helper.backtrace_frame_muted?("/srv/app/lib/orders.rb:3:in 'call'"))
    end

    it "mutes gem frames with the gem home stripped" do
      assert(helper.backtrace_frame_muted?("gems/karafka-2.5.0/lib/karafka/runner.rb:36:in 'call'"))
      assert(helper.backtrace_frame_muted?("karafka-2.5.0/lib/karafka/runner.rb:36:in 'call'"))
      assert(helper.backtrace_frame_muted?("rdkafka-0.20.0-x86_64-linux-gnu/lib/rdkafka.rb:1"))
    end

    it "mutes git gem frames with the gem home stripped" do
      assert(helper.backtrace_frame_muted?("karafka-a1b2c3d4e5f6/lib/karafka/runner.rb:36:in 'call'"))
      assert(helper.backtrace_frame_muted?("karafka-0123456789ab/lib/karafka/runner.rb:36:in 'call'"))
    end

    it "mutes gem frames installed in the application or kept with absolute paths" do
      assert(helper.backtrace_frame_muted?("vendor/bundle/ruby/3.4.0/gems/karafka-2.5.0/lib/a.rb:1"))
      assert(helper.backtrace_frame_muted?("/usr/local/bundle/gems/karafka-2.5.0/lib/a.rb:1"))
    end

    it "mutes Ruby frames" do
      assert(helper.backtrace_frame_muted?("<internal:thread_sync>:18:in 'pop'"))
      assert(helper.backtrace_frame_muted?("/usr/local/lib/ruby/3.4.0/monitor.rb:201:in 'synchronize'"))
    end

    it "mutes binstub and version manager shim frames" do
      assert(helper.backtrace_frame_muted?("/usr/local/bundle/bin/karafka:25:in '<main>'"))
      assert(helper.backtrace_frame_muted?("/home/user/.rbenv/shims/../bin/karafka:3:in 'load'"))
      assert(helper.backtrace_frame_muted?("/app/bin/karafka:27:in 'load'"))
    end

    it "does not mute application code in a directory named like an executable" do
      refute(helper.backtrace_frame_muted?("/app/lib/bin_packing/solver.rb:3:in 'call'"))
      refute(helper.backtrace_frame_muted?("bin/karafka_setup.rb:3:in 'call'"))
    end

    it "mutes the bundle executable frames" do
      assert(helper.backtrace_frame_muted?("/home/mencio/.rbenv/versions/3.3.0/bin/bundle:25:in 'load'"))
      assert(helper.backtrace_frame_muted?("/usr/local/bin/bundle:25:in '<main>'"))
      assert(helper.backtrace_frame_muted?("/usr/local/bin/bundler:25:in '<main>'"))
    end

    it "mutes JRuby core frames" do
      assert(helper.backtrace_frame_muted?("org/jruby/RubyArray.java:2097:in 'each'"))
      assert(helper.backtrace_frame_muted?("org/jruby/ext/monitor/Monitor.java:85:in 'synchronize'"))
      assert(helper.backtrace_frame_muted?("uri:classloader:/jruby/kernel/kernel.rb:28:in 'x'"))
      assert(helper.backtrace_frame_muted?("java/lang/Thread.java:1583:in 'run'"))
    end
  end

  describe "#backtrace_paths_prefix" do
    let(:web) { "/home/user/Karafka/karafka-web/lib/karafka/web" }
    let(:core) { "/home/user/Karafka/karafka/lib/karafka" }

    it "returns the directory prefix shared by the application frames" do
      backtrace = [
        "#{web}/processing/consumer.rb:16:in 'consume'",
        "gems/karafka-core-2.6.8/lib/karafka/core/monitoring/monitor.rb:42:in 'instrument'",
        "#{core}/processing/worker.rb:80:in 'process'"
      ].join("\n")

      assert_equal("/home/user/Karafka/", helper.backtrace_paths_prefix(backtrace))
    end

    it "ignores gem and Ruby frames living under a different root" do
      backtrace = [
        "/home/user/.rbenv/versions/3.3.0/lib/ruby/3.3.0/monitor.rb:201:in 'synchronize'",
        "#{web}/processing/consumer.rb:16:in 'consume'",
        "#{web}/management/migrator.rb:44:in 'call'"
      ].join("\n")

      assert_equal("#{web}/", helper.backtrace_paths_prefix(backtrace))
    end

    it "is not shortened by the binstub frame of the main thread" do
      backtrace = [
        "/srv/app/src/consumers/orders_consumer.rb:12:in 'consume'",
        "/srv/app/src/lib/pricing.rb:42:in 'call'",
        "/usr/local/bundle/bin/karafka:25:in 'load'"
      ].join("\n")

      assert_equal("/srv/app/src/", helper.backtrace_paths_prefix(backtrace))
    end

    it "looks across all the given backtraces" do
      assert_equal(
        "/home/user/Karafka/",
        helper.backtrace_paths_prefix("#{web}/a.rb:1", "#{core}/b.rb:2")
      )
    end

    it "returns nil without at least two absolute application frames" do
      assert_nil(helper.backtrace_paths_prefix("app/jobs/visitors_job.rb:9:in 'perform'"))
      assert_nil(helper.backtrace_paths_prefix("#{web}/a.rb:1\napp/b.rb:2"))
      assert_nil(helper.backtrace_paths_prefix(nil))
    end

    it "returns nil when the shared prefix is too short to be worth collapsing" do
      assert_nil(helper.backtrace_paths_prefix("/srv/a.rb:1\n/opt/b.rb:2"))
      assert_nil(helper.backtrace_paths_prefix("/srv/a.rb:1\n/srv/b.rb:2"))
    end
  end

  describe "#backtrace_frame" do
    it "escapes application frames without wrapping them" do
      assert_equal("app/a.rb:1:in &#39;call&#39;", helper.backtrace_frame("app/a.rb:1:in 'call'"))
    end

    it "mutes gem frames" do
      assert_equal(
        '<span class="text-muted">gems/karafka-2.5.0/lib/a.rb:1</span>',
        helper.backtrace_frame("gems/karafka-2.5.0/lib/a.rb:1")
      )
    end

    it "makes the given prefix collapsible" do
      assert_equal(
        '<span class="backtrace-prefix">/srv/app/</span>' \
        '<span class="backtrace-ellipsis"></span>lib/a.rb:1:in &lt;main&gt;',
        helper.backtrace_frame("/srv/app/lib/a.rb:1:in <main>", "/srv/app/")
      )
    end

    it "leaves frames outside of the prefix intact" do
      assert_equal("/opt/b.rb:2", helper.backtrace_frame("/opt/b.rb:2", "/srv/app/"))
    end
  end
end
