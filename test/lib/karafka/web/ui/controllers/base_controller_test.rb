# frozen_string_literal: true

# We use this spec to check that pro components are not available when not in pro
describe_current do
  let(:app) { Karafka::Web::Ui::App }

  let(:make_better) { "Please help us make the Karafka ecosystem better" }
  let(:ui_config) { Karafka::Web.config.ui }

  describe "#health" do
    before { get "health" }

    it do
      refute_predicate(response, :ok?)
      assert_includes(body, make_better)
      assert_equal(402, status)
    end
  end

  describe "#explorer" do
    before { get "explorer" }

    it do
      refute_predicate(response, :ok?)
      assert_includes(body, make_better)
      assert_equal(402, status)
    end
  end

  describe "#dlq" do
    before { get "dlq" }

    it do
      refute_predicate(response, :ok?)
      assert_includes(body, make_better)
      assert_equal(402, status)
    end
  end

  describe "custom assets" do
    let(:custom_css) { "assets/#{Karafka::Web::VERSION}/stylesheets/custom.css" }
    let(:custom_js) { "assets/#{Karafka::Web::VERSION}/javascripts/custom.js" }

    after do
      ui_config.custom.css = false
      ui_config.custom.js = false
    end

    context "when there is no custom css" do
      before { get custom_css }

      it do
        refute_predicate(response, :ok?)
        assert_equal(404, status)
      end

      context "when rendering the layout" do
        before { get "ux" }

        it do
          assert_predicate(response, :ok?)
          refute_includes(body, "custom.css")
        end
      end

      context "when reaching an error page" do
        before { get "not-found" }

        it do
          refute_includes(body, "custom.css")
        end
      end
    end

    context "when there is custom inline css" do
      let(:css_content) { "div { display: none }" }

      before do
        ui_config.custom.css = css_content

        get custom_css
      end

      it do
        assert_predicate(response, :ok?)
        assert_equal(200, status)
        assert_equal(css_content, body)
        assert_equal("text/css", headers["content-type"])
        assert_equal("max-age=31536000, immutable", headers["cache-control"])
      end

      context "when rendering the layout" do
        before { get "ux" }

        it do
          assert_predicate(response, :ok?)
          assert_includes(body, "custom.css")
        end
      end

      context "when reaching an error page" do
        before { get "not-found" }

        it do
          assert_includes(body, "custom.css")
        end
      end
    end

    context "when there is custom css path that points to nothing" do
      let(:css_content) { "/nothing/really" }

      before do
        ui_config.custom.css = css_content

        get custom_css
      end

      it "expect to treat is as a stringified content" do
        assert_predicate(response, :ok?)
        assert_equal(200, status)
        assert_equal(css_content, body)
        assert_equal("text/css", headers["content-type"])
        assert_equal("max-age=31536000, immutable", headers["cache-control"])
      end

      context "when rendering the layout" do
        before { get "ux" }

        it do
          assert_predicate(response, :ok?)
          assert_includes(body, "custom.css")
        end
      end

      context "when reaching an error page" do
        before { get "not-found" }

        it do
          assert_includes(body, "custom.css")
        end
      end
    end

    context "when there is custom css path that points to a file to show" do
      let(:css_content) { File.join(Karafka::Web.gem_root, "Gemfile") }

      let(:fetched_content) { File.read(css_content) }

      before do
        ui_config.custom.css = css_content

        get custom_css
      end

      it "expect to treat is as a stringified content" do
        assert_predicate(response, :ok?)
        assert_equal(200, status)
        assert_equal(fetched_content, body)
        assert_equal("text/css", headers["content-type"])
        assert_equal("max-age=31536000, immutable", headers["cache-control"])
      end

      context "when rendering the layout" do
        before { get "ux" }

        it do
          assert_predicate(response, :ok?)
          assert_includes(body, "custom.css")
        end
      end

      context "when reaching an error page" do
        before { get "not-found" }

        it do
          assert_includes(body, "custom.css")
        end
      end
    end

    context "when there is no custom js" do
      before { get custom_js }

      it do
        refute_predicate(response, :ok?)
        assert_equal(404, status)
      end

      context "when rendering the layout" do
        before { get "ux" }

        it do
          assert_predicate(response, :ok?)
          refute_includes(body, "custom.js")
        end
      end

      context "when reaching an error page" do
        before { get "not-found" }

        it do
          refute_includes(body, "custom.js")
        end
      end
    end

    context "when there is custom inline js" do
      let(:js_content) { "div { display: none }" }

      before do
        ui_config.custom.js = js_content

        get custom_js
      end

      it do
        assert_predicate(response, :ok?)
        assert_equal(200, status)
        assert_equal(js_content, body)
        assert_equal("application/javascript", headers["content-type"])
        assert_equal("max-age=31536000, immutable", headers["cache-control"])
      end

      context "when rendering the layout" do
        before { get "ux" }

        it do
          assert_predicate(response, :ok?)
          assert_includes(body, "custom.js")
        end
      end

      context "when reaching an error page" do
        before { get "not-found" }

        it do
          assert_includes(body, "custom.js")
        end
      end
    end

    context "when there is custom js path that points to nothing" do
      let(:js_content) { "/nothing/really" }

      before do
        ui_config.custom.js = js_content

        get custom_js
      end

      it "expect to treat is as a stringified content" do
        assert_predicate(response, :ok?)
        assert_equal(200, status)
        assert_equal(js_content, body)
        assert_equal("application/javascript", headers["content-type"])
        assert_equal("max-age=31536000, immutable", headers["cache-control"])
      end

      context "when rendering the layout" do
        before { get "ux" }

        it do
          assert_predicate(response, :ok?)
          assert_includes(body, "custom.js")
        end
      end

      context "when reaching an error page" do
        before { get "not-found" }

        it do
          assert_includes(body, "custom.js")
        end
      end
    end

    context "when there is custom js path that points to a file to show" do
      let(:js_content) { File.join(Karafka::Web.gem_root, "Gemfile") }

      let(:fetched_content) { File.read(js_content) }

      before do
        ui_config.custom.js = js_content

        get custom_js
      end

      it "expect to treat is as a stringified content" do
        assert_predicate(response, :ok?)
        assert_equal(200, status)
        assert_equal(fetched_content, body)
        assert_equal("application/javascript", headers["content-type"])
        assert_equal("max-age=31536000, immutable", headers["cache-control"])
      end

      context "when rendering the layout" do
        before { get "ux" }

        it do
          assert_predicate(response, :ok?)
          assert_includes(body, "custom.js")
        end
      end

      context "when reaching an error page" do
        before { get "not-found" }

        it do
          assert_includes(body, "custom.js")
        end
      end
    end
  end

  describe "custom nav" do
    before do
      ui_config.custom.nav_erb = nav_erb

      get "dashboard"
    end

    after { ui_config.custom.nav_erb = false }

    context "when nav_erb is set to an erb template code" do
      let(:nav_erb) do
        <<~ERB
          <strong><%= 100 %></strong>
        ERB
      end

      it "expect to render it" do
        assert_predicate(response, :ok?)
        assert_includes(body, "<strong>100</strong>")
      end
    end

    context "when it is set to a non-existing file" do
      let(:nav_erb) { "/tmp/does-not-exist" }

      it "expect to render it as an erb string" do
        assert_predicate(response, :ok?)
        assert_includes(body, "/tmp/does-not-exist")
      end
    end

    context "when it is set to an existing custom user erb component" do
      let(:nav_erb) { Fixtures.path("custom/nav.erb") }

      it "expect to render it" do
        assert_predicate(response, :ok?)
        assert_includes(body, "this is a test")
      end
    end
  end
end
