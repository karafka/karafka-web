# frozen_string_literal: true

RSpec.describe_current do
  subject(:clean) { described_class.new.call }

  let(:boot_file) { Tempfile.new }

  before { allow(Karafka).to receive(:boot_file).and_return(boot_file) }

  context "when the boot file contains the web setup code" do
    before do
      content = <<~CODE
        some other stuff
        Karafka::Web.enable!
        other stuff
      CODE

      File.write(boot_file, content)
    end

    it "expect to remove the web setup code and leave the rest" do
      clean
      expect(File.read(boot_file)).to eq("some other stuff\nother stuff\n")
    end
  end

  context "when the boot file does not contain the web setup code" do
    before { File.write(boot_file, "nothing") }

    it "expect not to change the content of the boot file" do
      clean
      expect(File.read(boot_file)).to eq("nothing")
    end
  end
end
