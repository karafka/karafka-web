# frozen_string_literal: true

describe_current do
  let(:pagination) { described_class.call(partitions_count, page) }

  context "when there is only one partition" do
    let(:partitions_count) { 1 }
    let(:page) { 1 }

    it { assert_equal([0], pagination[0]) }
    it { assert_equal(1, pagination[1]) }
    it { refute(pagination[2]) }
  end

  context "when there are 25 partitions (matching per page)" do
    let(:partitions_count) { 25 }
    let(:page) { 1 }

    it { assert_equal((0..24).to_a, pagination[0]) }
    it { assert_equal(1, pagination[1]) }
    it { refute(pagination[2]) }
  end

  context "when there are 26 partitions and first page" do
    let(:partitions_count) { 26 }
    let(:page) { 1 }

    it { assert_equal((0..12).to_a, pagination[0]) }
    it { assert_equal(1, pagination[1]) }
    it { assert(pagination[2]) }
  end

  context "when there are 26 partitions and second page" do
    let(:partitions_count) { 26 }
    let(:page) { 2 }

    it { assert_equal((13..25).to_a, pagination[0]) }
    it { assert_equal(1, pagination[1]) }
    it { assert(pagination[2]) }
  end

  context "when there are 26 partitions and a third page" do
    let(:partitions_count) { 26 }
    let(:page) { 3 }

    it { assert_equal((0..12).to_a, pagination[0]) }
    it { assert_equal(2, pagination[1]) }
    it { assert(pagination[2]) }
  end

  context "when there are 109 partitions and first page" do
    let(:partitions_count) { 109 }
    let(:page) { 1 }

    it { assert_equal((0..21).to_a, pagination[0]) }
    it { assert_equal(1, pagination[1]) }
    it { assert(pagination[2]) }
  end

  context "when there are 109 partitions and second page" do
    let(:partitions_count) { 109 }
    let(:page) { 2 }

    it { assert_equal((22..43).to_a, pagination[0]) }
    it { assert_equal(1, pagination[1]) }
    it { assert(pagination[2]) }
  end

  context "when there are 109 partitions and a third page" do
    let(:partitions_count) { 109 }
    let(:page) { 3 }

    it { assert_equal((44..65).to_a, pagination[0]) }
    it { assert_equal(1, pagination[1]) }
    it { assert(pagination[2]) }
  end
end
