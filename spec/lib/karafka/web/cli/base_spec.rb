# frozen_string_literal: true

RSpec.describe_current do
  subject(:base_cli_class) { described_class }

  describe '#commands' do
    let(:expected_commands) do
      [
        Karafka::Web::Cli::Help,
        Karafka::Web::Cli::Install,
        Karafka::Web::Cli::Migrate,
        Karafka::Web::Cli::Reset,
        Karafka::Web::Cli::Uninstall
      ]
    end

    it 'expect to include all supported commands' do
      expect(base_cli_class.commands).to eq(expected_commands)
    end
  end
end
