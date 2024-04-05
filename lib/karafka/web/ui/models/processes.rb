# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Represents the active processes data
        # @note Active also includes processes stopped recently. We use it to provide better
        #   visibility via UI.
        module Processes
          class << self
            include ::Karafka::Core::Helpers::Time

            # Returns the active processes in an array and alongside of that the current state of
            # the system. We use those together in the UI and it would be expensive to pick it up
            # while we've already had it.
            #
            # @param state [State] current system state from which we can get processes metadata
            # @return [Array<Process>]
            def active(state)
              messages = fetch_reports(state)
              messages = squash_processes_data(messages)
              processes = messages.map(&:payload)
              evict_expired_processes(processes)
              processes = sort_processes(processes)

              processes.map { |process_hash| Process.new(process_hash) }
            end

            private

            # Fetches the relevant processes reports from the reports topic
            # @param state [State]
            # @return [Array<Hash>] array with deserialized processes reports
            def fetch_reports(state)
              processes = state[:processes]

              # Short track when no processes not to run a read when nothing will be given
              # This allows us to handle a case where we would load 10k of reports for nothing
              return [] if processes.empty?

              offsets = processes
                        .values
                        .map { |process| process[:offset] }
                        .sort

              Lib::Admin.read_topic(
                ::Karafka::Web.config.topics.consumers.reports,
                0,
                # We set 10k here because we start from the latest offset of the reports, hence
                # we will never get this much. Do do not know however exactly how many reports
                # we may get as for some processes we may get few if the reporting interval
                # was bypassed by state changes in the processes
                10_000,
                offsets.first || -1
              )
            end

            # Collapses processes data and only keeps the most recent report for give process
            # @param processes [Array<Hash>]
            # @return [Array<Hash>] unique processes data
            def squash_processes_data(processes)
              processes
                .reverse
                .uniq(&:key)
                .reverse
            end

            # Removes processes that are no longer active. They may still be here because the state
            # may have a small lag but we want to compensate for it that way.
            # @param processes [Array<Hash>]
            # @return [Array<Hash>] only active processes data
            def evict_expired_processes(processes)
              max_ttl = ::Karafka::Web.config.ttl / 1_000
              now = float_now

              processes.delete_if do |details|
                now - details[:dispatched_at] > max_ttl
              end
            end

            # Ensures that we always return processes sorted by their id
            # @param processes [Array<Hash>]
            # @return [Array<Hash>] sorted processes data
            def sort_processes(processes)
              processes.sort_by { |consumer| consumer[:process][:id] }
            end
          end
        end
      end
    end
  end
end
