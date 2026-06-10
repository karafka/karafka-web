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
        assert(response.ok?)
        assert_body(no_errors)
        assert_body(support_message)
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
        assert(response.ok?)
        refute_body(no_errors)
        assert_body("shinra:1555833:4e8f7174ae53")
        assert_equal(3, body.scan("StandardError:").size)
        refute_body(pagination)
        assert_body(support_message)
        assert_body("high: 3")
        assert_body("low: 0")
        assert_body(breadcrumbs)
      end
    end

    context "when there are enough errors for pagination to kick in" do
      before do
        produce_many(errors_topic, Array.new(30) { error_report })

        get "errors"
      end

      it do
        assert(response.ok?)
        refute_body(no_errors)
        assert_body("shinra:1555833:4e8f7174ae53")
        assert_equal(25, body.scan("StandardError:").size)
        assert_body(pagination)
        assert_body(support_message)
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
        assert(response.ok?)
        refute_body(no_errors)
        assert_body("shinra:1555833:4e8f7174ae53")
        assert_equal(25, body.scan("StandardError:").size)
        assert_body(pagination)
        assert_body(support_message)
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
        assert(response.ok?)
        refute_body(no_errors)
        assert_body("shinra:1555833:4e8f7174ae53")
        assert_equal(1, body.scan("StandardError:").size)
        assert_body(pagination)
        assert_body(support_message)
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
        assert(response.ok?)
        refute_body(no_errors)
        assert_equal(0, body.scan("StandardError:").size)
        refute_body(pagination)
        assert_body("high: 30")
        assert_body(support_message)
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

    context "when visiting error that does exist" do
      before do
        produce(errors_topic, error_report)
        get "errors/0"
      end

      it do
        assert(response.ok?)
        refute_body(no_errors)
        assert_body("shinra:1555833:4e8f7174ae53")
        assert_equal(3, body.scan("StandardError").size)
        refute_body(pagination)
        assert_body(breadcrumbs)
        assert_body("app/jobs/visitors_job.rb:9:in")
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
        assert(response.ok?)
        refute_body("shinra:1555833:4e8f7174ae53")
        refute_body("StandardError")
        assert_body(breadcrumbs)
        assert_body(pagination)
        assert_body("The message has been removed")
        assert_body(support_message)
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
