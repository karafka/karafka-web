# frozen_string_literal: true

describe_current do
  let(:extend_boot_file) { described_class.new.call }

  let(:boot_file) { Tempfile.new }

  before { Karafka.stubs(:boot_file).returns(boot_file) }

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

      assert_equal(content, File.read(boot_file))
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

      assert_includes(File.read(boot_file), "\nKarafka::Web.enable!\n")
    end

    it "expect to add the configurator" do
      extend_boot_file
      updated = File.read(boot_file)

      assert_includes(updated, "config.ui.sessions.secret")
      assert_includes(updated, "Karafka::Web.setup do |config|")
    end
  end
end
