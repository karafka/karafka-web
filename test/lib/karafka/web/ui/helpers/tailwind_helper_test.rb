# frozen_string_literal: true

describe_current do
  include described_class

  describe "#action_link_button" do
    let(:result) do
      action_link_button(
        "<svg></svg> Delete",
        "/topics/test/delete",
        classes: "btn-error btn-sm",
        title: "Delete 'test' topic",
        disabled_reason: disabled_reason
      )
    end

    context "when the action is available" do
      let(:disabled_reason) { nil }

      it "expect to render a link with the escaped title" do
        assert_equal(
          '<a href="/topics/test/delete" class="btn btn-error btn-sm" ' \
          'title="Delete &#39;test&#39; topic"><svg></svg> Delete</a>',
          result
        )
      end
    end

    context "when the action is not available" do
      let(:disabled_reason) { "Topics management is <disabled>" }

      it "expect to render a disabled button without a link" do
        assert_includes(result, '<button type="button" class="btn btn-error btn-sm btn-disabled" disabled>')
        refute_includes(result, "href=")
        refute_includes(result, "Delete &#39;test&#39; topic")
      end

      it "expect the escaped reason in the wrapper title" do
        assert(result.start_with?('<span class="inline-flex align-middle" title="Topics management is &lt;disabled&gt;">'))
        assert(result.end_with?("<svg></svg> Delete</button></span>"))
      end
    end
  end

  describe "#action_icon_link" do
    let(:result) do
      action_icon_link(
        "<svg></svg>",
        "/explorer/topics/test/recent",
        title: "Display 'test' recent message",
        disabled_reason: disabled_reason,
        turbo: turbo
      )
    end

    let(:turbo) { true }

    context "when the action is available" do
      let(:disabled_reason) { nil }

      it "expect to render an icon link with the escaped title" do
        assert_equal(
          '<a href="/explorer/topics/test/recent" class="btn-action" ' \
          'title="Display &#39;test&#39; recent message"><svg></svg></a>',
          result
        )
      end

      context "when turbo is disabled" do
        let(:turbo) { false }

        it { assert_includes(result, 'title="Display &#39;test&#39; recent message" data-turbo="false">') }
      end
    end

    context "when the action is not available" do
      let(:disabled_reason) { "This topic is <empty>" }

      it "expect to render a disabled icon button with the escaped reason and no link" do
        assert_equal(
          '<span class="inline-flex" title="This topic is &lt;empty&gt;">' \
          '<button type="button" class="btn-action disabled" disabled><svg></svg></button></span>',
          result
        )
      end
    end
  end
end
