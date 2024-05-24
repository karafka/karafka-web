# frozen_string_literal: true

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          module Search
            # Search runner that selects proper matcher, sets the parameters and runs the search
            # We use the Pro Iterator for searching but this runner adds metadata tracking and
            # some other metrics that are useful in the Web UI
            class Runner
              include Karafka::Core::Helpers::Time

              # Metrics we collect during search for each partition + totals
              METRICS_BASE = {
                first_offset: -1,
                last_offset: -1,
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
                    partitions: @partitions_stats
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
                  matcher_class.name == matcher
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
                          Time.at(timestamp)
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

                per_partition = (limit / partitions_to_search.size)

                iterator.each do |message|
                  @current_partition = message.partition

                  @totals_stats[:checked] += 1
                  current_stats[:checked] += 1
                  current_stats[:last_offset] = message.offset

                  if current_stats[:first_offset].negative?
                    current_stats[:first_offset] = message.offset
                  end

                  if current_matcher.call(message, phrase)
                    @matched << message

                    current_stats[:matched] += 1
                    @totals_stats[:matched] += 1
                  end

                  message.clean!

                  if @totals_stats[:checked] >= limit
                    iterator.stop
                    next
                  end

                  if current_stats[:checked] >= per_partition
                    iterator.stop_current_partition
                    next
                  end
                end

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
