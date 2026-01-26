# frozen_string_literal: true

RSpec.describe_current do
  subject(:extend_boot_file) { described_class.new.call }

  let(:boot_file) { Tempfile.new }

  before { allow(Karafka).to receive(:boot_file).and_return(boot_file) }

  context "when the boot file contains the web setup code" do
    let(:content) do
      <<~CODE
        some other stuff
        Karafka::Web.enable!
        other stuff
      CODE
    end

    before { File.write(boot_file, content) }

    it "expect not to change the content at all" do
      extend_boot_file
      expect(File.read(boot_file)).to eq(content)
    end
  end

  context "when boot file does not have the web setup code" do
    let(:content) do
      <<~CODE
        some other stuff
        other stuff
      CODE
    end

    before { File.write(boot_file, content) }

    it "expect to add the enabled" do
      extend_boot_file
      expect(File.read(boot_file)).to include("\nKarafka::Web.enable!\n")
    end

    it "expect to add the configurator" do
      extend_boot_file
      updated = File.read(boot_file)
      expect(updated).to include("config.ui.sessions.secret")
      expect(updated).to include("Karafka::Web.setup do |config|")
    end
  end
end
