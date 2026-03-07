# frozen_string_literal: true

describe_current do
  let(:cli) { described_class.new }

  let(:installer) { Karafka::Web::Installer.new }

  before do
    Karafka::Web::Installer.stubs(:new).returns(installer)
    installer.stubs(:reset)
  end

  it "expect to reset using installer" do
    installer.expects(:reset)
    cli.call
  end
end
