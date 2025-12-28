# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  let(:comm) { 'This code is part of Karafka Pro, a commercial component not licensed under LGPL' }
  let(:see) { 'See LICENSE for details.' }

  Dir[Karafka::Web.gem_root.join('lib', 'karafka', 'web', 'pro', '**/*.*')].each do |pro_file|
    context "when checking #{pro_file}" do
      let(:content) { File.read(pro_file) }

      it { expect(content).to include(comm) }
      it { expect(content).to include(see) }
    end
  end

  pro_path = Karafka::Web.gem_root.join('spec', 'lib', 'karafka', 'web', 'pro', '**/*.*')

  Dir[pro_path].each do |pro_file|
    context "when checking #{pro_file}" do
      let(:content) { File.read(pro_file) }

      it { expect(content).to include(comm) }
      it { expect(content).to include(see) }
    end
  end

  # Validates that all spec files have timing data for parallel test balancing.
  # If this fails, run: bin/collect_timings
  describe 'spec timings' do
    let(:timings_dir) { Karafka::Web.gem_root.join('spec', 'timings') }

    describe 'regular specs' do
      let(:timings) { JSON.parse(File.read(timings_dir.join('regular.json'))) }

      let(:spec_files) do
        Dir[Karafka::Web.gem_root.join('spec', 'lib', 'karafka', 'web', '**', '*_spec.rb')]
          .reject { |f| f.include?('/pro/') }
          .map { |f| f.sub("#{Karafka::Web.gem_root}/", '') }
      end

      it 'has timing data for all regular spec files' do
        timing_keys = timings.keys.map { |k| k.delete_prefix('./') }
        missing = spec_files.reject { |f| timing_keys.include?(f) }

        expect(missing).to be_empty,
                           "Missing timing data for #{missing.size} files.\n" \
                           "Run: bin/collect_timings\n" \
                           "Missing:\n  #{missing.join("\n  ")}"
      end
    end

    describe 'pro specs' do
      let(:timings) { JSON.parse(File.read(timings_dir.join('pro.json'))) }

      let(:spec_files) do
        Dir[Karafka::Web.gem_root.join('spec', 'lib', 'karafka', 'web', 'pro', '**', '*_spec.rb')]
          .map { |f| f.sub("#{Karafka::Web.gem_root}/", '') }
      end

      it 'has timing data for all pro spec files' do
        timing_keys = timings.keys.map { |k| k.delete_prefix('./') }
        missing = spec_files.reject { |f| timing_keys.include?(f) }

        expect(missing).to be_empty,
                           "Missing timing data for #{missing.size} files.\n" \
                           "Run: bin/collect_timings\n" \
                           "Missing:\n  #{missing.join("\n  ")}"
      end
    end
  end
end
