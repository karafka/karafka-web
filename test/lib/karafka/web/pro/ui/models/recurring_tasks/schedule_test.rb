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
  let(:schedule) { described_class.new(attrs) }

  let(:attrs) { { tasks: {} } }

  describe "#tasks" do
    context "when no tasks" do
      it { assert_equal([], schedule.tasks) }
    end

    context "when tasks are present" do
      let(:attrs) do
        {
          tasks: {
            task1: {
              id: "task1",
              cron: "* * * * *"
            }
          }
        }
      end

      it { assert_kind_of(Karafka::Web::Pro::Ui::Models::RecurringTasks::Task, schedule.tasks.first) }
      it { assert_kind_of(Array, schedule.tasks) }
      it { assert_equal("task1", schedule.tasks.first.id) }
    end
  end
end
