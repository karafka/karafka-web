# frozen_string_literal: true

RSpec.describe_current do
  let(:previous_offset) { 10 }
  let(:current_offset) { 20 }
  let(:next_offset) { 30 }
  let(:visible_offsets) { [10, 20, 30] }

  subject(:pagination) do
    described_class.new(
      previous_offset,
      current_offset,
      next_offset,
      visible_offsets
    )
  end

  describe "#paginate?" do
    context "when there is more than one page" do
      it "returns true" do
        expect(pagination.paginate?).to be true
      end
    end

    context "when there is only one page" do
      let(:previous_offset) { false }
      let(:next_offset) { false }

      it "returns false" do
        expect(pagination.paginate?).to be false
      end
    end
  end

  describe "#first_offset?" do
    context "when the current offset is not -1" do
      it "returns true" do
        expect(pagination.first_offset?).to be true
      end
    end

    context "when the current offset is -1" do
      let(:current_offset) { -1 }

      it "returns false" do
        expect(pagination.first_offset?).to be false
      end
    end
  end

  describe "#first_offset" do
    it "returns false" do
      expect(pagination.first_offset).to eq(-1)
    end
  end

  describe "#previous_offset?" do
    context "when previous offset is present" do
      it "returns true" do
        expect(pagination.previous_offset?).to be true
      end
    end

    context "when previous offset is not present" do
      let(:previous_offset) { false }

      it "returns false" do
        expect(pagination.previous_offset?).to be false
      end
    end
  end

  describe "#current_offset?" do
    it "returns false" do
      expect(pagination.current_offset?).to be true
    end
  end

  describe "#next_offset?" do
    context "when next offset is present" do
      it "returns true" do
        expect(pagination.next_offset?).to be true
      end
    end

    context "when next offset is not present" do
      let(:next_offset) { false }

      it "returns false" do
        expect(pagination.next_offset?).to be false
      end
    end
  end

  describe "#next_offset" do
    context "when next offset is present" do
      it "returns the next offset" do
        expect(pagination.next_offset).to eq(next_offset)
      end
    end

    context "when next offset is not present" do
      let(:next_offset) { false }

      it "returns 0" do
        expect(pagination.next_offset).to be 0
      end
    end
  end

  describe "#offset_key" do
    it 'returns "offset"' do
      expect(pagination.offset_key).to eq("offset")
    end
  end

  describe "#current_label" do
    context "when visible_offsets are empty" do
      let(:visible_offsets) { [] }

      it "returns an empty string" do
        expect(pagination.current_label).to eq("")
      end
    end

    context "when visible_offsets contain only one offset" do
      let(:visible_offsets) { [10] }

      it "returns the single offset as a string" do
        expect(pagination.current_label).to eq("10")
      end
    end

    context "when visible_offsets contain multiple offsets" do
      it "returns the range of the first and last offsets joined with a hyphen" do
        expect(pagination.current_label).to eq("10 - 30")
      end
    end

    context "when visible_offsets contain duplicate offsets" do
      let(:visible_offsets) { [10, 20, 10, 30, 30] }

      it "returns the unique offsets in the range" do
        expect(pagination.current_label).to eq("10 - 30")
      end
    end
  end
end
