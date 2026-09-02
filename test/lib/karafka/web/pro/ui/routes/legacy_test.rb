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
  # `describe_current` only wires the request helpers for `*Controller` specs, so a routes spec
  # that drives the app through HTTP has to pull them in explicitly.
  include Rack::Test::Methods
  include ControllerHelper

  let(:app) { Karafka::Web::Pro::Ui::App }

  describe "old top-level per-partition health paths" do
    # These moved to per-topic lenses under health/topics/<cg>/<topic>; the old paths redirect to
    # the aggregated topics view so existing links/bookmarks keep working.
    %w[overview lags offsets changes].each do |lens|
      context "when visiting the legacy health/#{lens} path" do
        before { get "health/#{lens}" }

        it "expect to redirect to the aggregated topics page" do
          assert_equal(302, response.status)
          assert_includes(response.headers["location"], "health/topics")
        end
      end
    end
  end
end
