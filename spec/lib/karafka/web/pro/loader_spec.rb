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
end
