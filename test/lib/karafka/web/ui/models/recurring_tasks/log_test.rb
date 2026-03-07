# frozen_string_literal: true

describe_current do
  let(:log) { described_class }

  it { assert(log < Karafka::Web::Ui::Lib::HashProxy) }
end
