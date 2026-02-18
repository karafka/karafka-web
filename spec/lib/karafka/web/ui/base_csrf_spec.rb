# frozen_string_literal: true

# Tests for Sec-Fetch-Site CSRF protection
# These tests verify CSRF protection works correctly for POST/PUT/DELETE requests
RSpec.describe Karafka::Web::Ui::Base do
  include Rack::Test::Methods

  describe "CSRF plugin configuration" do
    it "has sec_fetch_site_csrf plugin loaded" do
      expect(described_class.opts[:sec_fetch_site_csrf]).not_to be_nil
    end

    it "has csrf_failure set to :raise" do
      expect(described_class.opts[:sec_fetch_site_csrf][:csrf_failure]).to eq(:raise)
    end

    it "responds to check_sec_fetch_site! method" do
      expect(described_class.new({}).respond_to?(:check_sec_fetch_site!)).to eq(true)
    end
  end

  # Create a dedicated test app with CSRF protection enabled
  # We need this because spec_helper disables CSRF checks globally
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
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq("GET OK")
      end

      it "allows requests with any Sec-Fetch-Site header value" do
        header "Sec-Fetch-Site", "cross-site"
        get "/test"
        expect(last_response.status).to eq(200)
      end
    end

    context "with POST requests" do
      it "rejects requests without Sec-Fetch-Site header" do
        post "/test"
        expect(last_response.status).to eq(403)
        expect(last_response.body).to be_empty
      end

      it "rejects requests with cross-site header" do
        header "Sec-Fetch-Site", "cross-site"
        post "/test"
        expect(last_response.status).to eq(403)
      end

      it "rejects requests with same-site header" do
        header "Sec-Fetch-Site", "same-site"
        post "/test"
        expect(last_response.status).to eq(403)
      end

      it "allows requests with same-origin header" do
        header "Sec-Fetch-Site", "same-origin"
        post "/test"
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq("POST OK")
      end
    end

    context "with PUT requests" do
      it "rejects requests without Sec-Fetch-Site header" do
        put "/test"
        expect(last_response.status).to eq(403)
      end

      it "allows requests with same-origin header" do
        header "Sec-Fetch-Site", "same-origin"
        put "/test"
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq("PUT OK")
      end
    end

    context "with DELETE requests" do
      it "rejects requests without Sec-Fetch-Site header" do
        delete "/test"
        expect(last_response.status).to eq(403)
      end

      it "allows requests with same-origin header" do
        header "Sec-Fetch-Site", "same-origin"
        delete "/test"
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq("DELETE OK")
      end
    end
  end

  # Sanity check for actual OSS app
  describe "OSS App sanity check", type: :controller do
    let(:app) { Karafka::Web::Ui::App }

    it "allows GET requests to dashboard" do
      get "dashboard"
      expect(last_response.status).to eq(200)
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
      expect(last_response.status).to eq(403)
    end

    it "blocks POST requests with cross-site header" do
      header "Sec-Fetch-Site", "cross-site"
      post "ux"
      expect(last_response.status).to eq(403)
    end
  end
end
