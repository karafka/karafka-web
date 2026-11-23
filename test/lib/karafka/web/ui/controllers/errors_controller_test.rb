# frozen_string_literal: true

describe_current do
  let(:app) { Karafka::Web::Ui::App }

  let(:errors_topic) { create_topic }
  let(:no_errors) { "There are no errors in this errors topic partition" }
  let(:error_report) { Fixtures.errors_file }

  before { topics_config.errors.name = errors_topic }

  describe "#index" do
    context "when needed topics are missing" do
      let(:errors_topic) { generate_topic_name }

      before { get "errors" }

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when there are no errors" do
      before { get "errors" }

      it do
        assert_ok
        assert_body(no_errors)
        assert_body(breadcrumbs)
        refute_body(pagination)
      end
    end

    context "when there are only few errors" do
      before do
        produce_many(errors_topic, Array.new(3) { error_report })

        get "errors"
      end

      it do
        assert_ok
        refute_body(no_errors)
        assert_body("shinra:1555833:4e8f7174ae53")
        assert_equal(3, body.scan("StandardError:").size)
        refute_body(pagination)
        assert_body("high: 3")
        assert_body("low: 0")
        assert_body(breadcrumbs)
      end
    end

    context "when the errors topic contains a non-deserializable message" do
      before do
        produce(errors_topic, error_report)
        produce(errors_topic, "this is not valid json")

        get "errors"
      end

      it "renders the valid errors and a placeholder instead of 500-ing" do
        assert_ok
        assert_body("shinra:1555833:4e8f7174ae53")
        assert_body("not a valid Karafka error report")
      end
    end

    context "when the errors topic contains a foreign json message published by a user" do
      before do
        produce(errors_topic, error_report)
        produce(errors_topic, { foo: "bar" }.to_json)

        get "errors"
      end

      it "renders a placeholder for the foreign message instead of 500-ing" do
        assert_ok
        assert_body("shinra:1555833:4e8f7174ae53")
        assert_body("not a valid Karafka error report")
      end
    end

    context "when the errors topic contains a message with a corrupt zlib body" do
      before do
        produce(errors_topic, error_report)
        # A `zlib` header makes the deserializer inflate the body, which fails for non-zlib bytes
        produce(errors_topic, "this is not zlib compressed", headers: { "zlib" => "true" })

        get "errors"
      end

      it "renders a placeholder for the corrupt message instead of 500-ing" do
        assert_ok
        assert_body("shinra:1555833:4e8f7174ae53")
        assert_body("not a valid Karafka error report")
      end
    end

    context "when the errors topic contains a tombstone (null payload) message" do
      before do
        produce(errors_topic, error_report)
        # A tombstone / null-value record has a nil raw payload, so the deserializer has nothing
        # to parse. It must return nil rather than raise on `JSON.parse(nil)`.
        produce(errors_topic, nil)

        get "errors"
      end

      it "renders a placeholder for the tombstone instead of 500-ing" do
        assert_ok
        assert_body("shinra:1555833:4e8f7174ae53")
        assert_body("not a valid Karafka error report")
      end
    end

    context "when the errors topic contains a tombstone with a zlib header" do
      before do
        produce(errors_topic, error_report)
        # A nil payload must short-circuit before the `zlib` inflate too, otherwise
        # `Zlib::Inflate.inflate(nil)` raises a `TypeError`.
        produce(errors_topic, nil, headers: { "zlib" => "true" })

        get "errors"
      end

      it "renders a placeholder for the tombstone instead of 500-ing" do
        assert_ok
        assert_body("shinra:1555833:4e8f7174ae53")
        assert_body("not a valid Karafka error report")
      end
    end

    context "when there are enough errors for pagination to kick in" do
      before do
        produce_many(errors_topic, Array.new(30) { error_report })

        get "errors"
      end

      it do
        assert_ok
        refute_body(no_errors)
        assert_body("shinra:1555833:4e8f7174ae53")
        assert_equal(25, body.scan("StandardError:").size)
        assert_body(pagination)
        assert_body("high: 30")
        assert_body("low: 0")
        assert_body(breadcrumbs)
      end
    end

    context "when we want to visit second offset page with pagination" do
      before do
        produce_many(errors_topic, Array.new(30) { error_report })

        get "errors?offset=0"
      end

      it do
        assert_ok
        refute_body(no_errors)
        assert_body("shinra:1555833:4e8f7174ae53")
        assert_equal(25, body.scan("StandardError:").size)
        assert_body(pagination)
        assert_body("high: 30")
        assert_body("low: 0")
        assert_body(breadcrumbs)
      end
    end

    context "when we want to visit high offset page with pagination" do
      before do
        produce_many(errors_topic, Array.new(30) { error_report })

        get "errors?offset=29"
      end

      it do
        assert_ok
        refute_body(no_errors)
        assert_body("shinra:1555833:4e8f7174ae53")
        assert_equal(1, body.scan("StandardError:").size)
        assert_body(pagination)
        assert_body("high: 30")
        assert_body("low: 0")
        assert_body(breadcrumbs)
      end
    end

    context "when we want to visit page beyond pagination" do
      before do
        produce_many(errors_topic, Array.new(30) { error_report })

        get "errors?offset=129"
      end

      it do
        assert_ok
        refute_body(no_errors)
        assert_equal(0, body.scan("StandardError:").size)
        refute_body(pagination)
        assert_body("high: 30")
        assert_body("low: 0")
        assert_body(breadcrumbs)
      end
    end
  end

  describe "#show" do
    context "when visiting offset that does not exist" do
      before { get "errors/123456" }

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when visiting a non-deserializable message" do
      before do
        produce(errors_topic, "this is not valid json")
        get "errors/0"
      end

      it "renders the empty-offset placeholder instead of 500-ing" do
        assert_ok
        assert_body("not a valid Karafka error report")
      end
    end

    context "when visiting a foreign json message published by a user" do
      before do
        produce(errors_topic, { foo: "bar" }.to_json)
        get "errors/0"
      end

      it "renders the empty-offset placeholder instead of 500-ing" do
        assert_ok
        assert_body("not a valid Karafka error report")
      end
    end

    context "when visiting error that does exist" do
      before do
        produce(errors_topic, error_report)
        get "errors/0"
      end

      it do
        assert_ok
        refute_body(no_errors)
        assert_body("shinra:1555833:4e8f7174ae53")
        assert_equal(3, body.scan("StandardError").size)
        refute_body(pagination)
        assert_body(breadcrumbs)
        assert_body("app/jobs/visitors_job.rb:9:in")
      end
    end

    context "when visiting an error with a backtrace" do
      before do
        produce(errors_topic, error_report)
        get "errors/0"
      end

      it "expect to render it as plain text with gem frames muted and application ones plain" do
        assert_body('<code class="wrapped hljs nohighlight p-0 m-0">')
        refute_body("wrapped json")
        assert_body("app/jobs/visitors_job.rb:9:in")
        refute_body('<span class="text-muted">app/jobs/visitors_job.rb')
        refute_body('<span class="font-bold">app/')
        assert_body('<span class="text-muted">gems/activejob-7.0.6/lib/active_job/')
      end

      it "expect to render one frame per line" do
        assert_body(
          "in `perform&#39;\n" \
          '<span class="text-muted">gems/activejob-7.0.6/lib/active_job/execution.rb:65:in'
        )
      end
    end

    context "when visiting an error with absolute application paths" do
      let(:root) { "/home/user/Karafka" }

      before do
        report = JSON.parse(error_report)
        report["backtrace"] = [
          "#{root}/karafka-web/lib/karafka/web/processing/consumer.rb:16:in 'consume'",
          "gems/karafka-core-2.6.8/lib/karafka/core/monitoring/monitor.rb:42:in 'instrument'",
          "#{root}/karafka/lib/karafka/processing/worker.rb:80:in 'process'"
        ].join("\n")
        produce(errors_topic, report.to_json)
        get "errors/0"
      end

      it "expect to collapse their shared prefix by default with a toggle to expand it" do
        assert_body('<div id="backtrace-paths" class="backtrace-short-paths">')
        assert_body('class="btn-action btn-toggle-backtrace-paths"')
        assert_body(
          '<span class="backtrace-prefix">/home/user/Karafka/</span>' \
          '<span class="backtrace-ellipsis">…/</span>karafka-web/lib/karafka/web/processing/consumer.rb'
        )
        assert_body('<span class="text-muted">gems/karafka-core-2.6.8/lib/')
      end
    end

    context "when visiting an error with only relative paths" do
      before do
        report = JSON.parse(error_report)
        report["backtrace"] = [
          "app/jobs/visitors_job.rb:9:in 'perform'",
          "gems/activejob-7.0.6/lib/active_job/execution.rb:65:in 'block in _perform_job'"
        ].join("\n")
        produce(errors_topic, report.to_json)
        get "errors/0"
      end

      it "expect not to offer collapsing paths" do
        assert_body("app/jobs/visitors_job.rb:9:in")
        refute_body("btn-toggle-backtrace-paths")
        refute_body("backtrace-prefix")
      end
    end

    context "when visiting a forceful shutdown error carrying blocking details" do
      let(:error_report) do
        Fixtures.errors_json.merge(
          type: "app.stopping.error",
          error_class: "Karafka::Errors::ForcefulShutdownError",
          details: {
            alive_workers: 2,
            active_listeners: "listener-1 (sub-group-1)",
            in_processing: "Consume orders/0 (sub-group-1, blocking)"
          }
        ).to_json
      end

      before do
        produce(errors_topic, error_report)
        get "errors/0"
      end

      it "expect to render the forceful shutdown blocking details" do
        assert_ok
        assert_body("app.stopping.error")
        assert_body("ForcefulShutdownError")
        # The details are rendered as regular rows in the generic error details table
        assert_body("active_listeners")
        assert_body("listener-1 (sub-group-1)")
        assert_body("in_processing")
        assert_body("Consume orders/0 (sub-group-1, blocking)")
        assert_body("alive_workers")
      end
    end

    context "when visiting a producer dispatch error with a delivery outcome" do
      let(:error_report) do
        Fixtures.errors_json.merge(
          type: "librdkafka.dispatch_error",
          details: {
            topic: "default",
            partition: 2,
            offset: -1,
            delivery_status: Rdkafka::Bindings::RD_KAFKA_MSG_STATUS_POSSIBLY_PERSISTED,
            latency_ms: 12.35,
            broker_id: 1
          }
        ).to_json
      end

      before do
        produce(errors_topic, error_report, partition: 0)
        get "errors/0"
      end

      it "expect to render the delivery outcome details" do
        assert_ok
        assert_body('<span class="badge badge-warning">possibly persisted</span>')
        assert_body("details.latency_ms")
        assert_body("12.35")
        assert_body("details.broker_id")
      end
    end

    context "when visiting a producer dispatch error with an unknown delivery status" do
      let(:error_report) do
        Fixtures.errors_json.merge(
          type: "librdkafka.dispatch_error",
          details: { topic: "default", partition: 2, offset: -1, delivery_status: "<b>x</b>" }
        ).to_json
      end

      before do
        produce(errors_topic, error_report, partition: 0)
        get "errors/0"
      end

      it "expect to render it escaped in a neutral badge" do
        assert_ok
        assert_body('<span class="badge badge-secondary">&lt;b&gt;x&lt;/b&gt;</span>')
        refute_body("<b>x</b>")
      end
    end

    context "when visiting error offset with a transactional record in range" do
      before do
        produce(errors_topic, error_report, partition: 0, type: :transactional)

        # Sleep so watermark offsets and transaction is reflected
        sleep(1)

        get "errors/1"
      end

      it do
        assert_ok
        refute_body("shinra:1555833:4e8f7174ae53")
        refute_body("StandardError")
        assert_body(breadcrumbs)
        assert_body(pagination)
        assert_body("The message has been removed")
      end
    end

    context "when visiting offset on transactional above watermark" do
      before do
        produce(errors_topic, error_report, partition: 0, type: :transactional)

        get "errors/2"
      end

      it do
        refute(response.ok?)
        assert_equal(404, status)
      end
    end

    context "when viewing an error but having a different one in the offset" do
      before { get "errors/0?offset=1" }

      it "expect to redirect to the one from the offset" do
        assert_equal(302, response.status)
        assert_includes(response.headers["location"], "errors/1")
      end
    end
  end
end
