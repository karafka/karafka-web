# frozen_string_literal: true

describe_current do
  let(:cli_class) { described_class }

  describe "#commands" do
    let(:expected_commands) do
      [
        Karafka::Web::Cli::Help,
        Karafka::Web::Cli::Install,
        Karafka::Web::Cli::Migrate,
        Karafka::Web::Cli::Reset,
        Karafka::Web::Cli::Uninstall
      ]
    end

    it "expect to include all supported commands" do
      assert_equal(expected_commands, cli_class.send(:commands))
    end
  end
end
