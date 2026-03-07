# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

describe_current do
  let(:listener) { described_class.new }
  let(:iterator_double) { stub() }
  let(:message) { stub() }

  before do
    Karafka::Pro::Iterator.stubs(:new).returns(iterator_double)
    Karafka.monitor.stubs(:instrument)
  end

  describe "#each" do
    context "when all good" do
      before { iterator_double.stubs(:each).yields(message) }

      it "yields messages from the iterator" do
        yielded_args = nil
        listener.each(proc { |*yargs| yielded_args = yargs })
        refute_nil(yielded_args, 'Expected block to yield')
        assert_equal([message], yielded_args)
      end
    end

    context "when an error occurs" do
      before do
        iterator_double.stubs(:each).yields(message).then.raises(StandardError)

        Karafka.monitor.stubs(:instrument)
      end

      it "reports the error and retries" do
        Karafka.monitor.expects(:instrument)
        listener.each do
          listener.stop
        end

      end
    end

    context "when stop is requested" do
      before do
        iterator_double.stubs(:each).yields(message)
        iterator_double.stubs(:stop)
      end

      it "stops iterating over messages" do
        iterator_double.expects(:stop)
        listener.stop
        listener.each { |_| }

      end
    end
  end
end
