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

describe_current do
  describe "#post_setup" do
    let(:config) { Karafka::Web.config }

    context "when commanding is enabled" do
      before do
        config.commanding.active = true

        Karafka.monitor.stubs(:subscribe)
      end

      it "subscribes the Commanding Manager to the Karafka monitor" do
        Karafka.monitor.expects(:subscribe).with(Karafka::Web::Pro::Commanding::Manager.instance)
        described_class.post_setup(config)
      end
    end

    context "when commanding is not enabled" do
      before do
        config.commanding.active = false

        Karafka::Web::Pro::Commanding::Contracts::Config.stubs(:new)
        Karafka.monitor.stubs(:subscribe)
      end

      after { config.commanding.active = true }

      it "does not subscribe the Commanding Manager to the Karafka monitor" do
        Karafka::Web::Pro::Commanding::Contracts::Config.expects(:new).never
        Karafka.monitor.expects(:subscribe).never
        described_class.post_setup(config)
      end
    end

    context "when commanding config is invalid" do
      before { config.commanding.active = "invalid" }

      after { config.commanding.active = true }

      it "raises an error" do
        assert_raises(Karafka::Errors::InvalidConfigurationError) { described_class.post_setup(config) }
      end
    end
  end
end
