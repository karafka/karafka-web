# frozen_string_literal: true

describe_current do
  let(:app) { Karafka::Web::Ui::App }

  describe "#show" do
    before { get "support" }

    it do
      assert_predicate(response, :ok?)
      assert_includes(body, support_message)
      assert_includes(body, breadcrumbs)
    end
  end
end
