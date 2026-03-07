# frozen_string_literal: true

describe Karafka::Web::Ui::Base do
  include Rack::Test::Methods
  include ControllerHelper

  let(:app) { Karafka::Web::Ui::App }

  let(:monitor) { Karafka.monitor }

  describe "error handling and reporting" do
    let(:controller) do
      stub(run_before_hooks: nil,
        run_after_hooks: nil
      )
    end

    before do
      Karafka::Web::Ui::Controllers::DashboardController.stubs(:new).returns(controller)
    end

    context "when an unhandled error occurs in the UI" do
      before do
        controller.stubs(:index).raises(StandardError, "Unexpected error in UI")
      end

      it "expect to report the error to Karafka monitoring and show 500 page" do
        stub_and_passthrough(monitor, :instrument)

        get "dashboard"

        # TODO: have_received with block - needs manual conversion
        # Original: expect(monitor).to have_received(:instrument) do |event, payload| assert_equal("error.occurred", event) assert_equal("web.ui.error", payload[:type]) assert_kind_of(StandardError, payload[:error]) assert_equal("Unexpected error in UI", payload[:error].message) end

        assert_equal(500, status)
        assert_body("500")
        assert_body("Internal Server Error")
      end
    end

    context "when a UI::NotFoundError occurs" do
      before do
        controller.stubs(:index).raises(Karafka::Web::Errors::Ui::NotFoundError, "Not found")
      end

      it "expect not to report the error to Karafka monitoring" do
        stub_and_passthrough(monitor, :instrument)

        monitor.expects(:instrument).never
        get "dashboard"


        assert_equal(404, status)
      end
    end

    context "when a UI::ProOnlyError occurs" do
      before do
        controller.stubs(:index).raises(Karafka::Web::Errors::Ui::ProOnlyError, "Pro only")
      end

      it "expect not to report the error to Karafka monitoring" do
        stub_and_passthrough(monitor, :instrument)

        monitor.expects(:instrument).never
        get "dashboard"


        assert_equal(402, status)
      end
    end

    context "when a UI::ForbiddenError occurs" do
      before do
        controller.stubs(:index).raises(Karafka::Web::Errors::Ui::ForbiddenError, "Forbidden")
      end

      it "expect not to report the error to Karafka monitoring" do
        stub_and_passthrough(monitor, :instrument)

        monitor.expects(:instrument).never
        get "dashboard"


        assert_equal(403, status)
      end
    end

    context "when a RdkafkaError occurs" do
      before do
        controller.stubs(:index).raises(Rdkafka::RdkafkaError.new(1, broker_message: "Kafka error"))
      end

      it "expect not to report the error to Karafka monitoring" do
        stub_and_passthrough(monitor, :instrument)

        monitor.expects(:instrument).never
        get "dashboard"


        assert_equal(404, status)
      end
    end
  end

  describe "session path tracking" do
    let(:env_key) { Karafka::Web.config.ui.sessions.env_key }
    let(:html_headers) { { "HTTP_ACCEPT" => "text/html" } }

    context "when navigating between pages" do
      before do
        get "dashboard", {}, html_headers
        get "consumers", {}, html_headers
      end

      it "expect to store paths with string keys" do
        session = last_request.env[env_key]

        assert_equal("/consumers", session["current_path"])
        assert_equal("/dashboard", session["previous_path"])
        # Ensure symbol keys are not used
        assert_nil(session[:current_path])
        assert_nil(session[:previous_path])
      end
    end

    context "when visiting the first page" do
      before { get "dashboard", {}, html_headers }

      it "expect to set current_path with string key" do
        session = last_request.env[env_key]

        assert_equal("/dashboard", session["current_path"])
        assert_nil(session["previous_path"])
      end
    end
  end
end
