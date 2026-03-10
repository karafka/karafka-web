# frozen_string_literal: true

module Factories
  # Factory for building processing coordinators
  module Processing
    module_function

    # @param topic [Karafka::Routing::Topic] topic
    # @param partition [Integer] partition number
    # @param pause_tracker [Object] pause tracker
    # @param seek_offset [Integer, nil] seek offset
    # @param job_type [Symbol] job type
    # @return [Karafka::Processing::Coordinator]
    def build_coordinator(
      topic: nil,
      partition: 0,
      pause_tracker: nil,
      seek_offset: nil,
      job_type: :consume,
      **
    )
      topic ||= Factories::Routing.build_topic
      pause_tracker ||= Factories::TimeTrackers.build_pause

      coordinator = Karafka::Processing::Coordinator.new(topic, partition, pause_tracker)
      coordinator.increment(job_type)
      coordinator.seek_offset = seek_offset
      coordinator
    end
  end
end
