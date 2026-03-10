# frozen_string_literal: true

describe_current do
  let(:cli) { described_class.new }

  let(:installer) { stub(uninstall: nil) }

  before do
    Karafka::Web::Installer.stubs(:new).returns(installer)
  end

  it "expect to uninstall using installer" do
    installer.expects(:uninstall)
    cli.call
  end
end
