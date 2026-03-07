# frozen_string_literal: true

describe_current do
  let(:cli) { described_class.new }

  let(:commands) { Karafka::Web::Cli::Base.commands }

  it "expect to print the header" do
    output = capture_io { cli.call }.first
    assert(output.include?("Karafka Web UI commands:"))
  end

  it "expect to print all available commands with descriptions" do
    output = capture_io { cli.call }.first

    commands.each do |command|
      assert(output.include?(command.name), "Expected output to include #{command.name}")
      assert(output.include?(command.desc), "Expected output to include #{command.desc}")
    end
  end

  it "expect to have a proper description" do
    assert_equal("Describes available commands", described_class.desc)
  end
end
