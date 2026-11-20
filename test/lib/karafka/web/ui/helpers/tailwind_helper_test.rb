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
        assert(result.start_with?('<span class="inline-flex" title="Topics management is &lt;disabled&gt;">'))
        assert(result.end_with?("<svg></svg> Delete</button></span>"))
      end
    end
  end
end
