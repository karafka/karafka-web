# frozen_string_literal: true

describe_current do
  let(:app) { Karafka::Web::Ui::App }

  describe "#show" do
    before { get "ux" }

    it do
      assert_ok
      assert_body(breadcrumbs)
    end
  end
end
