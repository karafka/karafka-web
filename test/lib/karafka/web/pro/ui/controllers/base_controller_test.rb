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
  let(:app) { Karafka::Web::Pro::Ui::App }

  let(:ui_config) { Karafka::Web.config.ui }

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
        assert(response.ok?)
        assert_body("<strong>100</strong>")
      end
    end

    context "when it is set to a non-existing file" do
      let(:nav_erb) { "/tmp/does-not-exist" }

      it "expect to render it as an erb string" do
        assert(response.ok?)
        assert_body("/tmp/does-not-exist")
      end
    end

    context "when it is set to an existing custom user erb component" do
      let(:nav_erb) { Fixtures.path("custom/nav.erb") }

      it "expect to render it" do
        assert(response.ok?)
        assert_body("this is a test")
      end
    end
  end
end
