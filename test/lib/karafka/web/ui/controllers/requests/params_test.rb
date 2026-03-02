# frozen_string_literal: true

describe_current do
  let(:request_params) { { "page" => "2", "offset" => "10" } }

  let(:params) { described_class.new(request_params) }

  describe "#current_page" do
    context "when the page is a positive integer" do
      it "returns the current page" do
        assert_equal(2, params.current_page)
      end
    end

    context "when the page is not a positive integer" do
      let(:request_params) { { "page" => "invalid" } }

      it "returns 1" do
        assert_equal(1, params.current_page)
      end
    end

    context "when the page is not provided" do
      let(:request_params) { {} }

      it "returns 1" do
        assert_equal(1, params.current_page)
      end
    end
  end

  describe "#current_offset" do
    context "when the offset is a valid integer" do
      it "returns the current offset" do
        assert_equal(10, params.current_offset)
      end
    end

    context "when the offset is less than -1" do
      let(:request_params) { { "offset" => "-10" } }

      it "returns -1" do
        assert_equal(-1, params.current_offset)
      end
    end

    context "when the offset is not provided" do
      let(:request_params) { {} }

      it "returns -1" do
        assert_equal(-1, params.current_offset)
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
              assert_equal(allowed_range.to_sym, params.current_range)
            end
          end
        end
      end

      context "when range is not allowed" do
        let(:request_params) { { "range" => "not_allowed_range" } }

        it "returns the first allowed range as a symbol" do
          assert_equal(:seconds, params.current_range)
        end
      end
    end

    context "when range is not provided" do
      it "returns the first allowed range as a symbol" do
        assert_equal(:seconds, params.current_range)
      end
    end
  end

  describe "#current_partition" do
    context "when the partition is a valid integer" do
      let(:request_params) { { "partition" => "3" } }

      it "returns the current partition" do
        assert_equal(3, params.current_partition)
      end
    end

    context "when the partition is not provided" do
      let(:request_params) { {} }

      it "returns -1" do
        assert_equal(-1, params.current_partition)
      end
    end

    context "when the partition is not a valid integer" do
      let(:request_params) { { "partition" => "invalid" } }

      it "returns -1" do
        assert_equal(0, params.current_partition)
      end
    end
  end
end
