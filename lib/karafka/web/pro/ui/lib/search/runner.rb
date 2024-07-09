# frozen_string_literal: true

# This Karafka component is a Pro component under a commercial license.
# This Karafka component is NOT licensed under LGPL.
#
# All of the commercial components are present in the lib/karafka/pro directory of this
# repository and their usage requires commercial license agreement.
#
# Karafka has also commercial-friendly license, commercial support and commercial components.
#
# By sending a pull request to the pro components, you are agreeing to transfer the copyright of
# your code to Maciej Mensfeld.

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          module Search
            # Search runner that selects proper matcher, sets the parameters and runs the search
            # We use the Pro Iterator for searching but this runner adds metadata tracking and
            # some other metrics that are useful in the Web UI
            #
            # @note When running a search from latest, we stop when message timestamp is higher
            #   then the time when lookup started. This prevents us from iterating on topics for
            #   an extended time period when there are less messages than the requested amount but
            #   new are coming in real time. It acts as a virtual "eof".
            class Runner
              include Karafka::Core::Helpers::Time

              # Metrics we collect during search for each partition + totals
              METRICS_BASE = {
                first_message: false,
                last_message: false,
                checked: 0,
                matched: 0
              }.freeze

              # Fields that we use that come from the search query
              # Those fields are aliased here for cleaner code so we don't have to reference them
              # from the hash each time they are needed
              SEARCH_CRITERIA_FIELDS = %i[
                matcher
                limit
                offset
                offset_type
                partitions
                phrase
                timestamp
              ].freeze

              private_constant :METRICS_BASE, :SEARCH_CRITERIA_FIELDS

              # @param topic [String] topic in which we want to search
              # @param partitions_count [Integer] how many partitions this topic has
              # @param search_criteria [Hash] normalized search criteria
              def initialize(topic, partitions_count, search_criteria)
                @topic = topic
                @partitions_count = partitions_count
                @search_criteria = search_criteria
                @partitions_stats = Hash.new { |h, k| h[k] = METRICS_BASE.dup }
                @totals_stats = METRICS_BASE.dup
                @timeout = Web.config.ui.search.timeout
                @stop_reason = nil
                @matched = []
              end

              # Runs the search, collects search statistics and returns the results
              # @return [Array<Array<Karafka::Messages::Message>, Hash>] array with search results
              #   and metadata
              # @note Results are sorted based on the time value.
              def call
                search_with_stats

                [
                  # We return most recent results on top
                  @matched.sort_by(&:timestamp).reverse,
                  {
                    totals: @totals_stats,
                    partitions: @partitions_stats,
                    stop_reason: @stop_reason
                  }.freeze
                ]
              end

              private

              SEARCH_CRITERIA_FIELDS.each do |q|
                class_eval <<~RUBY, __FILE__, __LINE__ + 1
                  def #{q}
                    @#{q} ||= @search_criteria.fetch(:#{q})
                  end
                RUBY
              end

              # @return [#call] Finds and builds the lookup matcher
              # @note We create one instance for all matchings in a single search. That way in case
              #   someone would want a stateful matcher, this can be done.
              def current_matcher
                return @current_matcher if @current_matcher

                found_matcher_class = Web.config.ui.search.matchers.find do |matcher_class|
                  # Search only in active matchers for the current topic
                  matcher_class.active?(@topic) && matcher_class.name == matcher
                end

                # This should never happen. Report if you encounter this
                found_matcher_class || raise(Karafka::Errors::UnsupportedCaseError, matcher)

                @current_matcher = found_matcher_class.new
              end

              # @return [Karafka::Pro::Iterator]
              def iterator
                return @iterator if @iterator

                # Establish starting point
                start = case offset_type
                        when 'latest'
                          (limit / partitions_to_search.size) * -1
                        when 'offset'
                          offset
                        when 'timestamp'
                          # Kafka timestamp of message is in ms, we need a second precision for
                          # `Time#at`
                          Time.at(timestamp / 1_000.to_f)
                        else
                          # This should never happen. Contact us if you see this.
                          raise ::Karafka::Errors::UnsupportedCaseError, offset_type
                        end

                iterator_query = {
                  @topic => partitions_to_search.map { |par| [par, start] }.to_h
                }

                @iterator = Karafka::Pro::Iterator.new(iterator_query)
              end

              # Runs the search, measures its time and collects needed metrics
              # It uses the selected search matcher.
              def search_with_stats
                started_at = monotonic_now
                started_at_time = Time.now

                per_partition = (limit / partitions_to_search.size)
                # Ensure that in case we have a limit smaller than number of partitions, we check
                # at least one message (if any) per partition
                per_partition = 1 if per_partition.zero?

                iterator.each do |message|
                  @current_partition = message.partition

                  # If we reached the total limit of messages we should check per request
                  # If we are running search for too long, we should also stop. This prevents
                  # a case where slow matcher would cause Web UI to hang and never finish
                  if @totals_stats[:checked] >= limit
                    @stop_reason = :limit
                    iterator.stop
                    next
                  end

                  if (monotonic_now - started_at) > @timeout
                    @stop_reason = :timeout
                    iterator.stop
                    next
                  end

                  # If we checked enough per this partition or we reached the current time we
                  # should stop. We do not go beyond the moment if time of the moment when
                  # the lookup started to prevent endless lookups on partitions that have a lot
                  # of messages being written to them in real time
                  if current_stats[:checked] >= per_partition ||
                     message.timestamp > started_at_time
                    iterator.stop_current_partition
                    next
                  end

                  @totals_stats[:checked] += 1
                  current_stats[:checked] += 1
                  current_stats[:first_message] ||= message
                  current_stats[:last_message] = message

                  if current_matcher.call(message, phrase)
                    @matched << message

                    current_stats[:matched] += 1
                    @totals_stats[:matched] += 1
                  end

                  message.clean!
                end

                @stop_reason ||= :eof

                iterator.stop

                @totals_stats[:time_taken] = monotonic_now - started_at
              end

              # @return [Hash] statistics of the partition for which message we're currently
              #   checking.
              def current_stats
                @partitions_stats[@current_partition]
              end

              # @return [Array<Integer>] partitions in which we're supposed to search
              def partitions_to_search
                return @partitions_to_search if @partitions_to_search

                # Lets start with assumption that we search in all the partitions
                @partitions_to_search = (0...@partitions_count).to_a

                # If in the search query there is no "all", we pick only partitions that do exist
                # in the topic that were part of the requested search scope
                unless partitions.include?('all')
                  @partitions_to_search &= partitions.map(&:to_i)
                  # and just in case someone would provide really weird data, we fallback to
                  # partition 0
                  @partitions_to_search = [0] if @partitions_to_search.empty?
                end

                @partitions_to_search
              end
            end
          end
        end
      end
    end
  end
end
