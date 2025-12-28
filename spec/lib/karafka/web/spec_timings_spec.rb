# frozen_string_literal: true

# Validates that all spec files have timing references in the spec/timings/*.json files.
# This ensures the parallel test runner can properly balance spec execution.
#
# If this spec fails, run: bin/collect_timings all
RSpec.describe 'Spec Timings' do
  let(:timings_dir) { Karafka::Web.gem_root.join('spec', 'timings') }

  describe 'regular specs' do
    let(:timing_file) { timings_dir.join('regular.json') }
    let(:timings) { JSON.parse(File.read(timing_file)) }

    let(:spec_files) do
      Dir[Karafka::Web.gem_root.join('spec', 'lib', 'karafka', 'web', '**', '*_spec.rb')]
        .reject { |f| f.include?('/pro/') }
        .map { |f| f.sub("#{Karafka::Web.gem_root}/", '') }
    end

    it 'has timing data for all regular spec files' do
      # Timings may use either "spec/..." or "./spec/..." format
      timing_keys = timings.keys.map { |k| k.delete_prefix('./') }

      missing = spec_files.reject { |f| timing_keys.include?(f) }

      expect(missing).to be_empty,
        "Missing timing data for #{missing.size} files. Run: bin/collect_timings regular\n" \
        "Missing files:\n  #{missing.join("\n  ")}"
    end
  end

  describe 'pro specs' do
    let(:timing_file) { timings_dir.join('pro.json') }
    let(:timings) { JSON.parse(File.read(timing_file)) }

    let(:spec_files) do
      Dir[Karafka::Web.gem_root.join('spec', 'lib', 'karafka', 'web', 'pro', '**', '*_spec.rb')]
        .map { |f| f.sub("#{Karafka::Web.gem_root}/", '') }
    end

    it 'has timing data for all pro spec files' do
      # Timings may use either "spec/..." or "./spec/..." format
      timing_keys = timings.keys.map { |k| k.delete_prefix('./') }

      missing = spec_files.reject { |f| timing_keys.include?(f) }

      expect(missing).to be_empty,
        "Missing timing data for #{missing.size} files. Run: bin/collect_timings pro\n" \
        "Missing files:\n  #{missing.join("\n  ")}"
    end
  end
end
