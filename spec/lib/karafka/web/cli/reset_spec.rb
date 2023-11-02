# frozen_string_literal: true

RSpec.describe_current do
  subject(:cli) { described_class.new }

  let(:installer) { Karafka::Web::Installer.new }

  before do
    allow(Karafka::Web::Installer).to receive(:new).and_return(installer)
    allow(installer).to receive(:reset)
  end

  it 'expect to reset using installer' do
    cli.call
    expect(installer).to have_received(:reset)
  end
end
