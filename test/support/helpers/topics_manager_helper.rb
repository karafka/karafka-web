# frozen_string_literal: true

# Extra methods for topics management in specs
module TopicsManagerHelper
  # @return [String] random name of a topic with the integration suite prefix
  # @note Includes a short hash derived from the calling test file path so topics
  #   can be traced back to the test that created them in Kafka logs
  def generate_topic_name
    "it-#{caller_spec_hash}-#{SecureRandom.uuid}"
  end

  # @param topic_name [String] topic name. Default will generate automatically
  # @param partitions [Integer] number of partitions (one by default)
  # @return [String] generated topic name
  def create_topic(topic_name: generate_topic_name, partitions: 1)
    Karafka::Admin.create_topic(topic_name, partitions, 1)

    # Topic synchronization may take some time, especially when there are hundreds of partitions,
    # hence we check if topic is available and if not we wait
    # Slow topic creation can happen especially on CI
    loop do
      topics = Karafka::Admin.cluster_info.topics
      found = topics.find { |topic| topic[:topic_name] == topic_name }

      break if found

      sleep(0.1)
    end

    topic_name
  end

  # Sends data to Kafka in a sync way
  # @param topic [String] topic name
  # @param payload [String, nil] data we want to send
  # @param details [Hash] other details
  def produce(topic, payload = SecureRandom.uuid, details = {})
    type = details.delete(:type) || :regular

    PRODUCERS.public_send(type).produce_sync(
      **details,
      topic: topic,
      payload: payload
    )

    # Transactional messages may need a moment to become visible under heavy load
    sleep(0.1) if type == :transactional
  end

  # Sends multiple messages to kafka efficiently
  # @param topic [String] topic name
  # @param payloads [Array<String, nil>] data we want to send
  # @param details [Hash] other details
  def produce_many(topic, payloads, details = {})
    type = details.delete(:type) || :regular

    messages = payloads.map { |payload| details.merge(topic: topic, payload: payload) }

    PRODUCERS.public_send(type).produce_many_sync(messages)
  end

  # Draws expected routes
  def draw_routes(&)
    Karafka::App.routes.draw(&)
  end

  # Waits until the consumers state and metrics are readable from the currently configured
  # Web UI topics. After producing to a freshly created topic, there is a small window where
  # the just-produced messages are not yet visible to a fresh consumer (admin read) due to
  # broker metadata propagation. Tests that mutate the states/metrics topics and immediately
  # read them back (via the UI or via processing aggregators) need to ensure the data is
  # actually visible to avoid flakes.
  #
  # The Web UI read path is especially race-prone because it uses a short
  # `fetch.wait.max.ms` (100ms vs the default 500ms), so it gives up faster when the broker
  # has not yet propagated the just-produced message.
  #
  # Both the UI and the processing read paths are checked here so that the helper can be
  # used in UI controller tests as well as in processing aggregator tests.
  #
  # @param timeout [Numeric] maximum time to wait in seconds
  def wait_for_state_data(timeout: 10)
    deadline = Time.now + timeout

    loop do
      ui_ready = Karafka::Web::Ui::Models::ConsumersState.current &&
                 Karafka::Web::Ui::Models::ConsumersMetrics.current

      processing_ready = begin
        Karafka::Web::Processing::Consumers::State.current!
        Karafka::Web::Processing::Consumers::Metrics.current!
        true
      rescue Karafka::Web::Errors::Processing::MissingConsumersStateError,
             Karafka::Web::Errors::Processing::MissingConsumersMetricsError
        false
      end

      return if ui_ready && processing_ready

      if Time.now > deadline
        raise "Timed out after #{timeout}s waiting for consumers state/metrics to be readable"
      end

      sleep(0.1)
    end
  end

  private

  # Short hash (6 chars) derived from the calling test file path for topic name traceability.
  # Since karafka-web runs all tests in a single minitest process, we use caller_locations
  # to find the originating test file rather than $PROGRAM_NAME.
  # @return [String] 6-character hex hash of the caller's relative path
  def caller_spec_hash
    loc = caller_locations.find { |l| l.path.end_with?("_test.rb") }
    path = loc && (loc.absolute_path || loc.path) || File.expand_path($PROGRAM_NAME)
    relative_path = path.delete_prefix("#{Karafka::Web.gem_root}/")
    Digest::MD5.hexdigest(relative_path)[0, 6]
  end
end
