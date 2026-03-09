# frozen_string_literal: true

describe_current do
  let(:cli) { described_class.new }

  let(:installer) { stub(install: nil) }

  before do
    Karafka::Web::Installer.stubs(:new).returns(installer)
    cli.stubs(:options).returns({ replication_factor: 1 })
  end

  it "expect to install using installer" do
    installer.expects(:install)
    cli.call
  end
end
