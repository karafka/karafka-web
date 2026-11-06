# frozen_string_literal: true

describe_current do
  include Rack::Test::Methods

  let(:app) { described_class }

  context "when there is no Pro license" do
    before { post "/", "{}", { "CONTENT_TYPE" => "application/json" } }

    it "refuses the request as a Pro-only feature" do
      assert_equal(402, last_response.status)
      assert_includes(last_response.body, "requires a Karafka Pro license")
    end
  end
end
