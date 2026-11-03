# frozen_string_literal: true

describe LinksValidator do
  let(:validator) do
    instance = LinksValidator.send(:new)
    instance.context = Struct.new(:described_class).new(Karafka::Web::Ui::Controllers::BaseController)
    instance
  end

  let(:links) { validator.send(:extract_links, body) }

  context "when hrefs use double and single quotes" do
    let(:body) { %(<a href="/double">a</a><a href='/single'>b</a>) }

    it { assert_equal(%w[/double /single], links) }
  end

  context "when the anchor tag spans multiple lines" do
    let(:body) { %(<a\n  class="btn"\n  href="/multi"\n>x</a>) }

    it { assert_equal(%w[/multi], links) }
  end

  context "when another attribute comes before href" do
    let(:body) { %(<a class="link" title="Go" href="/after">x</a>) }

    it { assert_equal(%w[/after], links) }
  end

  context "when there is a data-href attribute" do
    let(:body) { %(<a data-href="/data">x</a><div href="/div">y</div>) }

    it { assert_empty(links) }
  end

  context "when the href has HTML entities" do
    let(:body) { %(<a href="/search?a=1&amp;b=2&#39;">x</a>) }

    it { assert_equal(["/search?a=1&b=2'"], links) }
  end

  context "when there are anchors, external and empty links" do
    let(:body) { %(<a href="#top">a</a><a href="https://karafka.io">b</a><a href="">c</a>) }

    it { assert_empty(links) }
  end

  context "when extracting links from a rendered page" do
    # Not through Rack::Test, so the global links crawl does not visit this page
    let(:body) { Rack::MockRequest.new(Karafka::Web::Ui::App).get("/routing").body }

    it "finds the navigation links" do
      assert_includes(links, "/dashboard")
      assert_includes(links, "/jobs/running")
      assert_operator(links.size, :>, 5)
    end
  end

  context "when links point to pages of test topics" do
    let(:topic) { "it-a1b2c3-#{SecureRandom.uuid}" }
    let(:response) { stub(content_type: "text/html", body: body) }
    let(:body) do
      %w[
        /topics/%s/config
        /topics/__%s/config
        /explorer/topics/%s
        /explorer/topics/__%s
      ].map { |path| %(<a href="#{format(path, topic)}">x</a>) }.join
    end

    let(:page_context) { mock }

    before do
      page_context.stubs(:described_class).returns(Karafka::Web::Ui::Controllers::BaseController)
      validator.context = page_context
    end

    it "does not visit them" do
      page_context.expects(:get).never
      validator.validate_all!(response)
    end

    context "when links point to other pages of a test topic" do
      let(:paths) { ["/topics/#{topic}/replication", "/topics/#{topic}/config/retention.ms/edit"] }
      let(:body) { paths.map { |path| %(<a href="#{path}">x</a>) }.join }

      it "visits them" do
        paths.each { |path| page_context.expects(:get).with(path).once }
        page_context.stubs(:last_response).returns(stub(status: 200))
        validator.validate_all!(response)
      end
    end
  end
end
