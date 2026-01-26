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
  subject(:policy) { described_class.new }

  describe "#key?" do
    it { expect(policy.key?("irrelevant")).to be(true) }
  end

  describe "#headers?" do
    it { expect(policy.headers?("irrelevant")).to be(true) }
  end

  describe "#payload?" do
    context "when encryption is off" do
      let(:message) { Struct.new(:headers).new({}) }

      it { expect(policy.payload?(message)).to be(true) }
    end

    context "when encryption is on" do
      let(:message) { Struct.new(:headers).new({ "encryption" => true }) }

      it { expect(policy.payload?(message)).to be(false) }
    end
  end

  describe "#download?" do
    context "when encryption is off" do
      let(:message) { Struct.new(:headers).new({}) }

      it { expect(policy.download?(message)).to be(true) }
    end

    context "when encryption is on" do
      let(:message) { Struct.new(:headers).new({ "encryption" => true }) }

      it { expect(policy.download?(message)).to be(false) }
    end
  end

  describe "#export?" do
    context "when encryption is off" do
      let(:message) { Struct.new(:headers).new({}) }

      it { expect(policy.export?(message)).to be(true) }
    end

    context "when encryption is on" do
      let(:message) { Struct.new(:headers).new({ "encryption" => true }) }

      it { expect(policy.export?(message)).to be(false) }
    end
  end

  describe "#republish?" do
    it { expect(policy.republish?(nil)).to be(true) }
  end
end
