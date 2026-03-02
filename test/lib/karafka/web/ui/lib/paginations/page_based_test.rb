# frozen_string_literal: true

describe_current do
  let(:pagination) { described_class.new(current, show_next) }

  context "when page 1 and no more" do
    let(:current) { 1 }
    let(:show_next) { false }

    it { refute_predicate(pagination, :paginate?) }
    it { refute_predicate(pagination, :first_offset?) }
    it { refute(pagination.first_offset) }
  end

  context "when page 1 and more" do
    let(:current) { 1 }
    let(:show_next) { true }

    it { assert_predicate(pagination, :paginate?) }
    it { refute_predicate(pagination, :first_offset?) }
    it { refute(pagination.first_offset) }
    it { refute_predicate(pagination, :previous_offset?) }
    it { assert_equal(0, pagination.previous_offset) }
    it { assert_predicate(pagination, :current_offset?) }
    it { assert_equal(1, pagination.current_offset) }
    it { assert_equal(2, pagination.next_offset?) }
    it { assert_equal("page", pagination.offset_key) }
    it { assert_equal("1", pagination.current_label) }
  end

  context "when last page" do
    let(:current) { 10 }
    let(:show_next) { false }

    it { assert_predicate(pagination, :paginate?) }
    it { assert_predicate(pagination, :first_offset?) }
    it { refute(pagination.first_offset) }
    it { assert_predicate(pagination, :previous_offset?) }
    it { assert_equal(9, pagination.previous_offset) }
    it { assert_predicate(pagination, :current_offset?) }
    it { assert_equal(10, pagination.current_offset) }
    it { refute_predicate(pagination, :next_offset?) }
    it { assert_equal("page", pagination.offset_key) }
    it { assert_equal("10", pagination.current_label) }
  end
end
