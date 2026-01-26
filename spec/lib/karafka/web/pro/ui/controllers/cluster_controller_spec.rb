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

RSpec.describe_current do
  subject(:app) { Karafka::Web::Pro::Ui::App }

  describe "#index" do
    before { get "cluster" }

    it do
      expect(response).to be_ok
      expect(body).to include("ID")
      expect(body).to include(breadcrumbs)
      expect(body).not_to include(support_message)
    end

    context "when requests policy prevents us from visiting this page" do
      before do
        allow(Karafka::Web.config.ui.policies.requests)
          .to receive(:allow?)
          .and_return(false)

        get "cluster"
      end

      it do
        expect(response).not_to be_ok
        expect(response.status).to eq(403)
      end
    end
  end

  describe "#show" do
    context "when broker with given id does not exist" do
      before { get "cluster/123" }

      it do
        expect(response).not_to be_ok
        expect(status).to eq(404)
      end
    end

    context "when broker with given id exists" do
      before { get "cluster/1" }

      it do
        expect(response).to be_ok
        expect(body).to include(breadcrumbs)
        expect(body).not_to include(support_message)
        expect(body).to include("advertised.listeners")
        expect(body).to include("controller.quota.window.num")
        expect(body).to include("log.flush.interval.ms")
        expect(body).to include("9223372036854775807")
      end
    end
  end

  describe "#replication" do
    before { get "cluster/replication" }

    it do
      expect(response).to be_ok
      expect(body).to include(breadcrumbs)
      expect(body).not_to include(support_message)
    end

    context "when there are many pages with topics" do
      before { 30.times { create_topic } }

      context "when we visit existing page" do
        before { get "cluster/replication?page=2" }

        it do
          expect(response).to be_ok
          expect(body).to include(breadcrumbs)
          expect(body).to include(pagination)
          expect(body).not_to include(support_message)
        end
      end

      context "when we visit a non-existing page" do
        before { get "cluster/replication?page=100000000" }

        it do
          expect(response).to be_ok
          expect(body).to include(pagination)
          expect(body).to include(no_meaningful_results)
          expect(body).not_to include(support_message)
        end
      end
    end
  end
end
