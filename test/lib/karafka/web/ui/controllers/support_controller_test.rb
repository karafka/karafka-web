# frozen_string_literal: true

describe_current do
  let(:app) { Karafka::Web::Ui::App }

  describe "#show" do
    before { get "support" }

    it do
      assert(response.ok?)
      assert_body(breadcrumbs)
      assert_body("Karafka Pro")
    end
  end
end
