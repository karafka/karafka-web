# frozen_string_literal: true

describe_current do
  let(:cli) { described_class.new }

  let(:installer) { Karafka::Web::Installer.new }

  before do
    Karafka::Web::Installer.stubs(:new).returns(installer)
    installer.stubs(:uninstall)
  end

  it "expect to uninstall using installer" do
    installer.expects(:uninstall)
    cli.call
  end
end
