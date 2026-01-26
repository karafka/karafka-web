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
  let(:header_title) { "Karafka Pro - Source Available Commercial Software" }
  let(:header_license) { "License: https://karafka.io/docs/Pro-License-Comm/" }

  Dir[Karafka::Web.gem_root.join("lib", "karafka", "web", "pro", "**/*.*")].each do |pro_file|
    context "when checking #{pro_file}" do
      let(:content) { File.read(pro_file) }

      it { expect(content).to include(header_title) }
      it { expect(content).to include(header_license) }
    end
  end

  pro_path = Karafka::Web.gem_root.join("spec", "lib", "karafka", "web", "pro", "**/*.*")

  Dir[pro_path].each do |pro_file|
    context "when checking #{pro_file}" do
      let(:content) { File.read(pro_file) }

      it { expect(content).to include(header_title) }
      it { expect(content).to include(header_license) }
    end
  end

  # Validates that all spec files have timing data for parallel test balancing.
  # If this fails, run: bin/collect_timings
  describe "spec timings" do
    let(:timings_dir) { Karafka::Web.gem_root.join("spec", "timings") }

    describe "regular specs" do
      let(:timings) { JSON.parse(File.read(timings_dir.join("regular.json"))) }

      let(:spec_files) do
        Dir[Karafka::Web.gem_root.join("spec", "lib", "karafka", "web", "**", "*_spec.rb")]
          .reject { |f| f.include?("/pro/") }
          .map { |f| f.sub("#{Karafka::Web.gem_root}/", "") }
      end

      it "has timing data for all regular spec files" do
        timing_keys = timings.keys.map { |k| k.delete_prefix("./") }
        missing = spec_files.reject { |f| timing_keys.include?(f) }

        expect(missing).to be_empty,
          "Missing timing data for #{missing.size} files.\n" \
          "Run: bin/collect_timings\n" \
          "Missing:\n  #{missing.join("\n  ")}"
      end
    end

    describe "pro specs" do
      let(:timings) { JSON.parse(File.read(timings_dir.join("pro.json"))) }

      let(:spec_files) do
        Dir[Karafka::Web.gem_root.join("spec", "lib", "karafka", "web", "pro", "**", "*_spec.rb")]
          .map { |f| f.sub("#{Karafka::Web.gem_root}/", "") }
      end

      it "has timing data for all pro spec files" do
        timing_keys = timings.keys.map { |k| k.delete_prefix("./") }
        missing = spec_files.reject { |f| timing_keys.include?(f) }

        expect(missing).to be_empty,
          "Missing timing data for #{missing.size} files.\n" \
          "Run: bin/collect_timings\n" \
          "Missing:\n  #{missing.join("\n  ")}"
      end
    end
  end
end
