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
  subject(:contract) { described_class.new }

  let(:matcher) { Karafka::Web::Pro::Ui::Lib::Search::Matchers::RawHeaderIncludes }

  let(:params) do
    {
      ui: {
        search: {
          matchers: [matcher],
          limits: [100, 1000, 10_000],
          timeout: 100
        }
      }
    }
  end

  context "when all values are valid" do
    it "is valid" do
      expect(contract.call(params)).to be_success
    end
  end

  context "when matchers is not an array" do
    before { params[:ui][:search][:matchers] = "not_an_array" }

    it { expect(contract.call(params)).not_to be_success }
  end

  context "when matchers is an empty array" do
    before { params[:ui][:search][:matchers] = [] }

    it { expect(contract.call(params)).not_to be_success }
  end

  context "when a matcher does not respond to name" do
    let(:invalid_matcher) do
      Class.new do
        def call
          raise
        end
      end
    end

    before { params[:ui][:search][:matchers] = [invalid_matcher] }

    it { expect(contract.call(params)).not_to be_success }
  end

  context "when a matcher does not respond to call" do
    let(:invalid_matcher) do
      Class.new do
        def self.name
          "ExampleMatcher"
        end
      end
    end

    before { params[:ui][:search][:matchers] = [invalid_matcher] }

    it { expect(contract.call(params)).not_to be_success }
  end

  context "when matchers have duplicate names" do
    let(:duplicate_matcher) do
      Class.new do
        def self.name
          "ExampleMatcher"
        end

        def self.call
          # some implementation
        end
      end
    end

    before { params[:ui][:search][:matchers] = [matcher, duplicate_matcher] }

    it { expect(contract.call(params)).not_to be_success }
  end

  context "when limits is not an array" do
    before { params[:ui][:search][:limits] = "not_an_array" }

    it { expect(contract.call(params)).not_to be_success }
  end

  context "when limits is an empty array" do
    before { params[:ui][:search][:limits] = [] }

    it { expect(contract.call(params)).not_to be_success }
  end

  context "when limits contains negative numbers" do
    before { params[:ui][:search][:limits] = [-100] }

    it { expect(contract.call(params)).not_to be_success }
  end

  context "when limits contains non-numbers" do
    before { params[:ui][:search][:limits] = ["na"] }

    it { expect(contract.call(params)).not_to be_success }
  end

  context "when timeout is not an integer" do
    before { params[:ui][:search][:timeout] = [] }

    it { expect(contract.call(params)).not_to be_success }
  end

  context "when timeout is not positive" do
    before { params[:ui][:search][:timeout] = 0 }

    it { expect(contract.call(params)).not_to be_success }
  end
end
