# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

# Sanity check for Pro App Sec-Fetch-Site CSRF protection
RSpec.describe Karafka::Web::Pro::Ui::App do
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

  describe "CSRF sanity check", type: :controller do
    subject(:app) { Karafka::Web::Pro::Ui::App }

    it "allows GET requests to dashboard" do
      get "dashboard"
      expect(last_response.status).to eq(200)
    end
  end

  # Sanity check that CSRF blocking works with Pro app configuration
  describe "CSRF blocking" do
    # Create a test app that inherits Pro app behavior but with CSRF enabled
    let(:csrf_enabled_app) do
      Class.new(Karafka::Web::Pro::Ui::App) do
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
