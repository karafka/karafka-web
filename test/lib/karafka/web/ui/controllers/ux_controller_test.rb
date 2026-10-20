# frozen_string_literal: true

describe_current do
  let(:app) { Karafka::Web::Ui::App }

  describe "#show" do
    before { get "ux" }

    it do
      assert_ok
      assert_body(breadcrumbs)
      assert_body("Next ›")
    end
  end

  describe "templates encoding" do
    it "expect to read templates as UTF-8 regardless of the default external encoding" do
      assert_equal(Encoding::UTF_8, app.opts[:render][:template_opts][:default_encoding])
    end
  end
end
