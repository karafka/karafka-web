# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

describe_current do
  include Karafka::Web::Ui::Helpers::TailwindHelper
  include described_class

  describe "#action_form_button" do
    let(:result) do
      action_form_button(
        "<svg></svg> Stop",
        "/consumers/commanding/p1/stop",
        classes: "btn-error btn-sm btn-lockable",
        title: "Stop",
        disabled_reason: disabled_reason
      )
    end

    context "when the action is available" do
      let(:disabled_reason) { nil }

      it "expect to render a posting form with an enabled submit button" do
        assert_equal(
          '<form action="/consumers/commanding/p1/stop" method="post" ' \
          'class="inline-flex items-center align-middle" title="Stop">' \
          '<button type="submit" class="btn btn-error btn-sm btn-lockable"><svg></svg> Stop</button>' \
          "</form>",
          result
        )
      end
    end

    context "when the action is not available" do
      let(:disabled_reason) { "Only a running process can be <stopped>" }

      it "expect to disable the button and put the escaped reason in the form title" do
        assert_includes(result, 'title="Only a running process can be &lt;stopped&gt;"')
        assert_includes(result, 'class="btn btn-error btn-sm btn-lockable btn-disabled" disabled>')
        refute_includes(result, 'title="Stop"')
      end
    end
  end
end
