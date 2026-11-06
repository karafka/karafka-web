# frozen_string_literal: true

describe_current do
  let(:response) { described_class.call({}) }

  it do
    assert_equal(402, response[0])
    assert_equal("text/plain", response[1]["content-type"])
    assert_includes(response[2].join, "requires a Karafka Pro license")
  end
end
