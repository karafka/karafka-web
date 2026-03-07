# frozen_string_literal: true

describe_current do
  let(:cli) { described_class.new }

  let(:installer) { Karafka::Web::Installer.new }

  before do
    Karafka::Web::Installer.stubs(:new).returns(installer)
    installer.stubs(:migrate)
  end

  it "expect to migrate using installer" do
    installer.expects(:migrate)
    cli.call
  end
end
