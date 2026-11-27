# frozen_string_literal: true

describe_current do
  let(:admin) { described_class }
  let(:not_found_error) { Karafka::Web::Errors::Ui::NotFoundError }

  context "when the topic name is not a valid Kafka topic name" do
    let(:topic_name) { "a" * 513 }

    before do
      Karafka::Admin.expects(:topic_info).never
      Karafka::Admin.expects(:read_watermark_offsets).never
      Karafka::Admin.expects(:read_topic).never
    end

    it { assert_raises(not_found_error) { admin.topic_info(topic_name) } }
    it { assert_raises(not_found_error) { admin.topic_info("..") } }
    it { assert_raises(not_found_error) { admin.read_watermark_offsets(topic_name, 0) } }
    it { assert_raises(not_found_error) { admin.read_watermark_offsets("valid" => [0], topic_name => [0]) } }
    it { assert_raises(not_found_error) { admin.read_topic(topic_name, 0, 1) } }
  end

  context "when the topic name is the longest valid one" do
    let(:topic_name) { "a" * 249 }

    it "reaches the cluster" do
      Karafka::Admin.expects(:topic_info).with(topic_name).returns({})

      assert_equal({}, admin.topic_info(topic_name))
    end
  end

  context "when the topic name is made of dots only but valid" do
    it "reaches the cluster" do
      Karafka::Admin.expects(:topic_info).with("...").returns({})

      assert_equal({}, admin.topic_info("..."))
    end
  end

  context "when reading watermark offsets of a valid topic" do
    let(:topic) { create_topic }

    it { assert_equal([0, 0], admin.read_watermark_offsets(topic, 0)) }
    it { assert_equal({ topic => { 0 => [0, 0] } }, admin.read_watermark_offsets(topic => [0])) }
  end
end
