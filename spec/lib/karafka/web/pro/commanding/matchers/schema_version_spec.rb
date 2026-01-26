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
  subject(:matcher) { described_class.new(message) }

  let(:current_schema_version) { "1.2.0" }
  let(:message) do
    instance_double(
      Karafka::Messages::Message,
      payload: { schema_version: schema_version_value }
    )
  end

  before do
    stub_const("Karafka::Web::Pro::Commanding::Dispatcher::SCHEMA_VERSION", current_schema_version)
  end

  describe "#matches?" do
    context "when message schema version matches current" do
      let(:schema_version_value) { current_schema_version }

      it { expect(matcher.matches?).to be true }
    end

    context "when message schema version does not match current" do
      let(:schema_version_value) { "2.0.0" }

      it { expect(matcher.matches?).to be false }
    end

    context "when message schema version is older" do
      let(:schema_version_value) { "1.0.0" }

      it { expect(matcher.matches?).to be false }
    end

    context "when message schema version is nil" do
      let(:schema_version_value) { nil }

      it { expect(matcher.matches?).to be false }
    end
  end
end
