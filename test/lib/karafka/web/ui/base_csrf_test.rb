# frozen_string_literal: true

# Tests for Sec-Fetch-Site CSRF protection
# These tests verify CSRF protection works correctly for POST/PUT/DELETE requests
describe Karafka::Web::Ui::Base do
  include Rack::Test::Methods

  describe "CSRF plugin configuration" do
    it "has sec_fetch_site_csrf plugin loaded" do
      refute_nil(described_class.opts[:sec_fetch_site_csrf])
    end

    it "has csrf_failure set to :raise" do
      assert_equal(:raise, described_class.opts[:sec_fetch_site_csrf][:csrf_failure])
    end

    it "responds to check_sec_fetch_site! method" do
      assert_respond_to(described_class.new({}), :check_sec_fetch_site!)
    end
  end

  # Create a dedicated test app with CSRF protection enabled
  # We need this because test_helper disables CSRF checks globally
  let(:csrf_test_app) do
    Class.new(Roda) do
      plugin :all_verbs
      plugin :sec_fetch_site_csrf, csrf_failure: :empty_403

      route do |r|
        r.on "test" do
          check_sec_fetch_site!

          r.get { "GET OK" }
          r.post { "POST OK" }
          r.put { "PUT OK" }
          r.delete { "DELETE OK" }
        end
      end
    end
  end

  let(:app) { csrf_test_app }

  describe "Sec-Fetch-Site CSRF protection" do
    context "with GET requests" do
      it "allows requests without Sec-Fetch-Site header" do
        get "/test"

        assert_equal(200, last_response.status)
        assert_equal("GET OK", last_response.body)
      end

      it "allows requests with any Sec-Fetch-Site header value" do
        header "Sec-Fetch-Site", "cross-site"
        get "/test"

        assert_equal(200, last_response.status)
      end
    end

    context "with POST requests" do
      it "rejects requests without Sec-Fetch-Site header" do
        post "/test"

        assert_equal(403, last_response.status)
        assert_empty(last_response.body)
      end

      it "rejects requests with cross-site header" do
        header "Sec-Fetch-Site", "cross-site"
        post "/test"

        assert_equal(403, last_response.status)
      end

      it "rejects requests with same-site header" do
        header "Sec-Fetch-Site", "same-site"
        post "/test"

        assert_equal(403, last_response.status)
      end

      it "allows requests with same-origin header" do
        header "Sec-Fetch-Site", "same-origin"
        post "/test"

        assert_equal(200, last_response.status)
        assert_equal("POST OK", last_response.body)
      end
    end

    context "with PUT requests" do
      it "rejects requests without Sec-Fetch-Site header" do
        put "/test"

        assert_equal(403, last_response.status)
      end

      it "allows requests with same-origin header" do
        header "Sec-Fetch-Site", "same-origin"
        put "/test"

        assert_equal(200, last_response.status)
        assert_equal("PUT OK", last_response.body)
      end
    end

    context "with DELETE requests" do
      it "rejects requests without Sec-Fetch-Site header" do
        delete "/test"

        assert_equal(403, last_response.status)
      end

      it "allows requests with same-origin header" do
        header "Sec-Fetch-Site", "same-origin"
        delete "/test"

        assert_equal(200, last_response.status)
        assert_equal("DELETE OK", last_response.body)
      end
    end
  end

  # Sanity check for actual OSS app
  describe "OSS App sanity check", type: :controller do
    let(:app) { Karafka::Web::Ui::App }

    it "allows GET requests to dashboard" do
      get "dashboard"

      assert_equal(200, last_response.status)
    end
  end

  # Sanity check that CSRF blocking works with OSS app configuration
  describe "OSS App CSRF blocking" do
    # Create a test app that inherits OSS app behavior but with CSRF enabled
    let(:csrf_enabled_app) do
      Class.new(Karafka::Web::Ui::App) do
        plugin :sec_fetch_site_csrf, check_request_methods: %w[POST]
      end
    end

    let(:app) { csrf_enabled_app }

    it "blocks POST requests without Sec-Fetch-Site header" do
      post "ux"

      assert_equal(403, last_response.status)
    end

    it "blocks POST requests with cross-site header" do
      header "Sec-Fetch-Site", "cross-site"
      post "ux"

      assert_equal(403, last_response.status)
    end
  end
end
