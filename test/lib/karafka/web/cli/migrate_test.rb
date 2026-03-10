# frozen_string_literal: true

describe_current do
  let(:cli) { described_class.new }

  let(:installer) { stub(migrate: nil) }

  before do
    Karafka::Web::Installer.stubs(:new).returns(installer)
    cli.stubs(:options).returns({ replication_factor: 1 })
  end

  it "expect to migrate using installer" do
    installer.expects(:migrate)
    cli.call
  end
end
