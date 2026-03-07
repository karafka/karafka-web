# frozen_string_literal: true

describe_current do
  let(:app) { Karafka::Web::Ui::App }

  describe "#show" do
    before { get "support" }

    it do
      assert(response.ok?)
      assert_body(support_message)
      assert_body(breadcrumbs)
    end
  end
end
