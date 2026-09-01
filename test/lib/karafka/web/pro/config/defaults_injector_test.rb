# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

describe_current do
  let(:oss_injector) { Karafka::Web::Config::DefaultsInjector }
  let(:ui_kafka) { Karafka::Web.config.ui.kafka }

  it "expect to be prepended onto the OSS Web injector when Pro is enabled" do
    assert_includes oss_injector.singleton_class.ancestors, described_class
  end

  it "expect the OSS injector to still expose the Web UI kafka defaults through the overlay" do
    ui_kafka.each do |key, value|
      assert_equal value, oss_injector.defaults[key]
    end
  end

  describe "layering" do
    let(:injector) do
      base = { "fetch.wait.max.ms": 100, a: 1 }

      Class.new(Karafka::Core::Configurable::Injector) do
        define_singleton_method(:defaults) { base }
      end
    end

    before { injector.singleton_class.prepend(described_class) }

    it "expect to keep the base (super) defaults" do
      assert_equal 100, injector.defaults[:"fetch.wait.max.ms"]
      assert_equal 1, injector.defaults[:a]
    end

    it "expect to merge the Pro defaults on top of the base" do
      described_class::KAFKA_DEFAULTS.each do |key, value|
        assert_equal value, injector.defaults[key]
      end
    end

    it "expect not to mutate the base defaults when merging" do
      injector.defaults

      refute_same injector.defaults, described_class::KAFKA_DEFAULTS
    end
  end
end
