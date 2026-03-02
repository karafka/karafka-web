# frozen_string_literal: true

describe_current do
  let(:app) { Karafka::Web::Ui::App }

  describe "#show" do
    before { get "health/overview" }

    it do
      assert_equal(402, response.status)
      assert_includes(body, "This feature is available only to")
    end
  end
end
