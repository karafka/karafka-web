# frozen_string_literal: true

describe_current do
  let(:check) { described_class.new(context) }

  let(:context) { Karafka::Web::Ui::Models::Status::Context.new }

  describe "DSL configuration" do
    it { refute(described_class.independent?) }
    it { assert_equal(:enabled, described_class.dependency) }
    it { assert_equal({ time: nil }, described_class.halted_details) }
  end

  describe "#call" do
    context "when connection is fast" do
      let(:cluster_info) { Struct.new(:topics).new([]) }

      before do
        Karafka::Web::Ui::Models::ClusterInfo.stubs(:fetch).returns(cluster_info)
      end

      it "returns success" do
        result = check.call

        assert_equal(:success, result.status)
        assert_kind_of(Numeric, result.details[:time])
        assert(result.details[:time] < 1_000)
      end

      it "caches cluster_info in context" do
        check.call

        refute_nil(context.cluster_info)
        refute_nil(context.connection_time)
      end
    end

    context "when connection fails" do
      before do
        Karafka::Web::Ui::Models::ClusterInfo.stubs(:fetch).raises(Rdkafka::RdkafkaError.new(0))
      end

      it "returns failure" do
        result = check.call

        assert_equal(:failure, result.status)
        assert_equal(1_000_000, result.details[:time])
      end
    end

    context "when already connected (cached)" do
      before do
        context.connection_time = 500
        context.cluster_info = Struct.new(:topics).new([])
      end

      it "does not connect again" do
        Karafka::Web::Ui::Models::ClusterInfo.expects(:fetch).never
        Karafka::Web::Ui::Models::ClusterInfo.stubs(:fetch)

        result = check.call

        assert_equal(:success, result.status)
        assert_equal(500, result.details[:time])
      end
    end
  end
end
