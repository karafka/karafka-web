# frozen_string_literal: true

RSpec.describe_current do
  subject(:cli) { described_class.new }

  let(:installer) { Karafka::Web::Installer.new }

  before { allow(Karafka::Web::Installer).to receive(:new).and_return(installer) }

  describe '#install' do
    before { allow(installer).to receive(:install!) }

    it 'expect to install using installer' do
      cli.install
      expect(installer).to have_received(:install!)
    end
  end

  describe '#migrate' do
    before { allow(installer).to receive(:migrate!) }

    it 'expect to migrate using installer' do
      cli.migrate
      expect(installer).to have_received(:migrate!)
    end
  end

  describe '#reset' do
    before { allow(installer).to receive(:reset!) }

    it 'expect to reset using installer' do
      cli.reset
      expect(installer).to have_received(:reset!)
    end
  end

  describe '#uninstall' do
    before { allow(installer).to receive(:uninstall!) }

    it 'expect to uninstall using installer' do
      cli.uninstall
      expect(installer).to have_received(:uninstall!)
    end
  end
end
