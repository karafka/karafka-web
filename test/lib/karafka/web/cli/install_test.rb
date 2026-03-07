# frozen_string_literal: true

describe_current do
  let(:cli) { described_class.new }

  let(:installer) { Karafka::Web::Installer.new }

  before do
    Karafka::Web::Installer.stubs(:new).returns(installer)
    installer.stubs(:install)
  end

  it "expect to install using installer" do
    installer.expects(:install)
    cli.call
  end
end
