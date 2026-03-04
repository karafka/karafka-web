# frozen_string_literal: true

describe_current do
  let(:helper) do
    helper_class = Class.new do
      include Karafka::Web::Ui::Helpers::PathsHelper

      attr_accessor :env, :current_action_name

      def initialize(env = {}, current_action_name = nil)
        @env = env
        @current_action_name = current_action_name
      end
    end

    helper_class.new(env, current_action_name)
  end

  let(:env) { { "SCRIPT_NAME" => "/web-ui" } }
  let(:current_action_name) { :show }

  describe "#action?" do
    context "when checking for single action" do
      it "returns true when current action matches" do
        assert(helper.action?(:show))
      end

      it "returns false when current action does not match" do
        refute(helper.action?(:index))
      end
    end

    context "when checking for multiple actions" do
      it "returns true when any action matches" do
        assert(helper.action?(:index, :show, :edit))
      end

      it "returns false when no actions match" do
        refute(helper.action?(:index, :edit, :delete))
      end
    end

    context "with different current action names" do
      let(:current_action_name) { :create }

      it "correctly identifies the current action" do
        assert(helper.action?(:create))
        refute(helper.action?(:show))
      end
    end

    context "when current action name is nil" do
      let(:current_action_name) { nil }

      it "returns false for any action check" do
        refute(helper.action?(:show, :index))
      end

      it "returns true when checking for nil explicitly" do
        assert(helper.action?(nil))
      end
    end
  end

  describe "#flatten_params" do
    context "with simple hash" do
      it "flattens simple key-value pairs" do
        hash = { name: "John", age: 30 }
        result = helper.flatten_params("", hash)

        expect(result).to eq(
          {
            "name" => "John",
            "age" => "30"
          }
        )
      end

      it "converts all values to strings" do
        hash = { count: 42, active: true, score: 3.14 }
        result = helper.flatten_params("", hash)

        expect(result).to eq(
          {
            "count" => "42",
            "active" => "true",
            "score" => "3.14"
          }
        )
      end
    end

    context "with nested hash" do
      it "flattens nested hashes with bracket notation" do
        hash = {
          user: {
            name: "John",
            profile: {
              age: 30,
              city: "NYC"
            }
          }
        }

        result = helper.flatten_params("", hash)

        expect(result).to eq(
          {
            "user[name]" => "John",
            "user[profile][age]" => "30",
            "user[profile][city]" => "NYC"
          }
        )
      end

      it "handles deeply nested structures" do
        hash = {
          level1: {
            level2: {
              level3: {
                value: "deep"
              }
            }
          }
        }

        result = helper.flatten_params("", hash)

        expect(result).to eq(
          {
            "level1[level2][level3][value]" => "deep"
          }
        )
      end
    end

    context "with arrays" do
      it "flattens arrays with indexed notation" do
        hash = {
          tags: %w[ruby rails kafka]
        }

        result = helper.flatten_params("", hash)

        expect(result).to eq(
          {
            "tags[0]" => "ruby",
            "tags[1]" => "rails",
            "tags[2]" => "kafka"
          }
        )
      end

      it "handles arrays of hashes" do
        hash = {
          users: [
            { name: "John", age: 30 },
            { name: "Jane", age: 25 }
          ]
        }

        result = helper.flatten_params("", hash)

        expect(result).to eq(
          {
            "users[0][name]" => "John",
            "users[0][age]" => "30",
            "users[1][name]" => "Jane",
            "users[1][age]" => "25"
          }
        )
      end

      it "handles nested arrays" do
        hash = {
          matrix: [
            [1, 2],
            [3, 4]
          ]
        }

        result = helper.flatten_params("", hash)

        expect(result).to eq(
          {
            "matrix[0][0]" => "1",
            "matrix[0][1]" => "2",
            "matrix[1][0]" => "3",
            "matrix[1][1]" => "4"
          }
        )
      end
    end

    context "with mixed structures" do
      it "handles complex mixed nested structures" do
        hash = {
          config: {
            servers: %w[server1 server2],
            settings: {
              timeout: 30,
              retries: 3,
              features: {
                enabled: %w[feature1 feature2]
              }
            }
          },
          metadata: {
            version: "1.0.0"
          }
        }

        result = helper.flatten_params("", hash)

        expect(result).to include(
          {
            "config[servers][0]" => "server1",
            "config[servers][1]" => "server2",
            "config[settings][timeout]" => "30",
            "config[settings][retries]" => "3",
            "config[settings][features][enabled][0]" => "feature1",
            "config[settings][features][enabled][1]" => "feature2",
            "metadata[version]" => "1.0.0"
          }
        )
      end
    end

    context "with prefix parameter" do
      it "uses the provided prefix" do
        hash = { name: "John", age: 30 }
        result = helper.flatten_params("user", hash)

        expect(result).to eq(
          {
            "user[name]" => "John",
            "user[age]" => "30"
          }
        )
      end
    end

    context "with empty structures" do
      it "handles empty hash" do
        result = helper.flatten_params("", {})

        assert_equal({}, result)
      end

      it "handles empty array" do
        result = helper.flatten_params("tags", [])

        assert_equal({}, result)
      end

      it "handles hash with empty values" do
        hash = { empty_hash: {}, empty_array: [] }
        result = helper.flatten_params("", hash)

        assert_equal({}, result)
      end
    end
  end

  describe "#root_path" do
    context "with basic usage" do
      it "generates path from script name and arguments" do
        result = helper.root_path("topics", "test-topic")

        assert_equal("/web-ui/topics/test-topic", result)
      end

      it "handles single argument" do
        result = helper.root_path("consumers")

        assert_equal("/web-ui/consumers", result)
      end

      it "handles multiple arguments" do
        result = helper.root_path("explorer", "topics", "test-topic", "0", "100")

        assert_equal("/web-ui/explorer/topics/test-topic/0/100", result)
      end
    end

    context "with different script names" do
      let(:env) { { "SCRIPT_NAME" => "/custom/path" } }

      it "uses custom script name" do
        result = helper.root_path("topics")

        assert_equal("/custom/path/topics", result)
      end

      it "handles root path with empty script name" do
        empty_helper = helper.class.new({ "SCRIPT_NAME" => "" }, :show)
        result = empty_helper.root_path("topics")

        assert_equal("/topics", result)
      end
    end

    context "with no arguments" do
      it "returns just the script name with trailing slash" do
        result = helper.root_path

        assert_equal("/web-ui/", result)
      end
    end

    context "with numeric arguments" do
      it "handles numeric path components" do
        result = helper.root_path("partition", 0, "offset", 100)

        assert_equal("/web-ui/partition/0/offset/100", result)
      end
    end
  end

  describe "#asset_path" do
    it "generates versioned asset paths" do
      result = helper.asset_path("styles/main.css")
      expected_path = "/web-ui/assets/#{Karafka::Web::VERSION}/styles/main.css"

      assert_equal(expected_path, result)
    end

    it "handles different asset types" do
      js_path = helper.asset_path("scripts/app.js")
      img_path = helper.asset_path("images/logo.png")

      assert_includes(js_path, "assets/#{Karafka::Web::VERSION}/scripts/app.js")
      assert_includes(img_path, "assets/#{Karafka::Web::VERSION}/images/logo.png")
    end

    it "works with custom script names" do
      custom_helper = helper.class.new({ "SCRIPT_NAME" => "/custom" }, :show)
      result = custom_helper.asset_path("main.css")

      assert_equal("/custom/assets/#{Karafka::Web::VERSION}/main.css", result)
    end
  end

  describe "#explorer_path" do
    it "builds basic explorer paths" do
      result = helper.explorer_path("topics")

      assert_equal("/web-ui/explorer/topics", result)
    end

    it "handles multiple path components" do
      result = helper.explorer_path("topics", "test-topic", "partition", "0")

      assert_equal("/web-ui/explorer/topics/test-topic/partition/0", result)
    end

    it "compacts nil values from arguments" do
      result = helper.explorer_path("topics", nil, "test-topic", nil, "0")

      assert_equal("/web-ui/explorer/topics/test-topic/0", result)
    end

    it "handles nested array arguments" do
      result = helper.explorer_path(%w[topics test-topic], %w[partition 0])

      assert_equal("/web-ui/explorer/topics/test-topic/partition/0", result)
    end
  end

  describe "#explorer_topics_path" do
    it "builds topics explorer paths" do
      result = helper.explorer_topics_path("test-topic")

      assert_equal("/web-ui/explorer/topics/test-topic", result)
    end

    it "handles multiple arguments" do
      result = helper.explorer_topics_path("test-topic", "partition", "0")

      assert_equal("/web-ui/explorer/topics/test-topic/partition/0", result)
    end

    it "compacts nil values" do
      result = helper.explorer_topics_path("test-topic", nil, "0")

      assert_equal("/web-ui/explorer/topics/test-topic/0", result)
    end
  end

  describe "#explorer_messages_path" do
    it "builds messages explorer paths" do
      result = helper.explorer_messages_path("test-topic", "0", "100")

      assert_equal("/web-ui/explorer/messages/test-topic/0/100", result)
    end

    it "handles topic and partition only" do
      result = helper.explorer_messages_path("test-topic", "0")

      assert_equal("/web-ui/explorer/messages/test-topic/0", result)
    end

    it "compacts nil values" do
      result = helper.explorer_messages_path("test-topic", nil, "100")

      assert_equal("/web-ui/explorer/messages/test-topic/100", result)
    end
  end

  describe "#topics_path" do
    it "builds basic topics path" do
      result = helper.topics_path

      assert_equal("/web-ui/topics", result)
    end

    it "builds topics path with arguments" do
      result = helper.topics_path("test-topic", "details")

      assert_equal("/web-ui/topics/test-topic/details", result)
    end

    it "handles single topic argument" do
      result = helper.topics_path("test-topic")

      assert_equal("/web-ui/topics/test-topic", result)
    end
  end

  describe "#consumers_path" do
    it "builds basic consumers path" do
      result = helper.consumers_path

      assert_equal("/web-ui/consumers", result)
    end

    it "builds consumers path with arguments" do
      result = helper.consumers_path("consumer-group", "details")

      assert_equal("/web-ui/consumers/consumer-group/details", result)
    end

    it "handles consumer group argument" do
      result = helper.consumers_path("consumer-group")

      assert_equal("/web-ui/consumers/consumer-group", result)
    end
  end

  describe "#consumer_path" do
    it "builds consumer-specific paths" do
      result = helper.consumer_path("consumer-123", "details")

      assert_equal("/web-ui/consumers/consumer-123/details", result)
    end

    it "builds consumer path with just consumer ID" do
      result = helper.consumer_path("consumer-123")

      assert_equal("/web-ui/consumers/consumer-123", result)
    end

    it "handles multiple path components" do
      result = helper.consumer_path("consumer-123", "subscriptions", "topic-1")

      assert_equal("/web-ui/consumers/consumer-123/subscriptions/topic-1", result)
    end
  end

  describe "#scheduled_messages_explorer_path" do
    context "with all parameters" do
      it "builds complete scheduled messages explorer path" do
        result = helper.scheduled_messages_explorer_path(
          "scheduled-topic",
          "0",
          "100",
          "details"
        )

        expect(result).to eq(
          "/web-ui/scheduled_messages/explorer/topics/scheduled-topic/0/100/details"
        )
      end
    end

    context "with partial parameters" do
      it "builds path with topic name only" do
        result = helper.scheduled_messages_explorer_path("scheduled-topic")

        assert_equal("/web-ui/scheduled_messages/explorer/topics/scheduled-topic", result)
      end

      it "builds path with topic and partition" do
        result = helper.scheduled_messages_explorer_path("scheduled-topic", "0")

        assert_equal("/web-ui/scheduled_messages/explorer/topics/scheduled-topic/0", result)
      end

      it "builds path with topic, partition, and offset" do
        result = helper.scheduled_messages_explorer_path("scheduled-topic", "0", "100")

        assert_equal("/web-ui/scheduled_messages/explorer/topics/scheduled-topic/0/100", result)
      end
    end

    context "with nil parameters" do
      it "compacts nil values correctly" do
        result = helper.scheduled_messages_explorer_path("topic", nil, "100", nil)

        assert_equal("/web-ui/scheduled_messages/explorer/topics/topic/100", result)
      end

      it "handles all nil parameters except topic" do
        result = helper.scheduled_messages_explorer_path("topic", nil, nil, nil)

        assert_equal("/web-ui/scheduled_messages/explorer/topics/topic", result)
      end

      it "handles completely nil parameters" do
        result = helper.scheduled_messages_explorer_path

        assert_equal("/web-ui/scheduled_messages/explorer/topics", result)
      end
    end
  end

  describe "edge cases and integration" do
    context "with special characters in paths" do
      it "handles topic names with special characters" do
        result = helper.topics_path("test-topic_v1.0")

        assert_equal("/web-ui/topics/test-topic_v1.0", result)
      end

      it "handles consumer IDs with special characters" do
        result = helper.consumer_path("consumer-123_v2.0")

        assert_equal("/web-ui/consumers/consumer-123_v2.0", result)
      end
    end

    context "with empty script name environment" do
      let(:env) { { "SCRIPT_NAME" => "" } }

      it "handles empty script name gracefully" do
        result = helper.root_path("topics")

        assert_equal("/topics", result)
      end
    end

    context "when combining with flatten_params" do
      it "can be used together for complex URL building" do
        params = { filter: { status: "active", tags: %w[urgent bug] } }
        flattened = helper.flatten_params("", params)
        path = helper.topics_path

        assert_equal("active", flattened["filter[status]"])
        assert_equal("urgent", flattened["filter[tags][0]"])
        assert_equal("/web-ui/topics", path)
      end
    end
  end
end
