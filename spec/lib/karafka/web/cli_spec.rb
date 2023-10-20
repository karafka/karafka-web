# frozen_string_literal: true

RSpec.describe_current do
  subject(:cli) { described_class.new }

  let(:installer) { Karafka::Web::Installer.new }

  before { allow(Karafka::Web::Installer).to receive(:new).and_return(installer) }

  describe '#start' do
    pending
  end
end
