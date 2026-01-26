# frozen_string_literal: true

RSpec.describe_current do
  let(:request_params) { { "page" => "2", "offset" => "10" } }

  subject(:params) { described_class.new(request_params) }

  describe "#current_page" do
    context "when the page is a positive integer" do
      it "returns the current page" do
        expect(params.current_page).to eq(2)
      end
    end

    context "when the page is not a positive integer" do
      let(:request_params) { { "page" => "invalid" } }

      it "returns 1" do
        expect(params.current_page).to eq(1)
      end
    end

    context "when the page is not provided" do
      let(:request_params) { {} }

      it "returns 1" do
        expect(params.current_page).to eq(1)
      end
    end
  end

  describe "#current_offset" do
    context "when the offset is a valid integer" do
      it "returns the current offset" do
        expect(params.current_offset).to eq(10)
      end
    end

    context "when the offset is less than -1" do
      let(:request_params) { { "offset" => "-10" } }

      it "returns -1" do
        expect(params.current_offset).to eq(-1)
      end
    end

    context "when the offset is not provided" do
      let(:request_params) { {} }

      it "returns -1" do
        expect(params.current_offset).to eq(-1)
      end
    end
  end

  describe "#current_range" do
    context "when range is provided" do
      context "when range is allowed" do
        %w[seconds minutes hours days].each do |allowed_range|
          context "when range is #{allowed_range}" do
            let(:request_params) { { "range" => allowed_range } }

            it "returns the symbolized range" do
              expect(params.current_range).to eq(allowed_range.to_sym)
            end
          end
        end
      end

      context "when range is not allowed" do
        let(:request_params) { { "range" => "not_allowed_range" } }

        it "returns the first allowed range as a symbol" do
          expect(params.current_range).to eq(:seconds)
        end
      end
    end

    context "when range is not provided" do
      it "returns the first allowed range as a symbol" do
        expect(params.current_range).to eq(:seconds)
      end
    end
  end

  describe "#current_partition" do
    context "when the partition is a valid integer" do
      let(:request_params) { { "partition" => "3" } }

      it "returns the current partition" do
        expect(params.current_partition).to eq(3)
      end
    end

    context "when the partition is not provided" do
      let(:request_params) { {} }

      it "returns -1" do
        expect(params.current_partition).to eq(-1)
      end
    end

    context "when the partition is not a valid integer" do
      let(:request_params) { { "partition" => "invalid" } }

      it "returns -1" do
        expect(params.current_partition).to eq(0)
      end
    end
  end
end
