# frozen_string_literal: true

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          module Search
            module Runner
              extend Karafka::Core::Helpers::Time

              class << self
                def call(topic, partitions_count, search_criteria)
                  t = monotonic_now

                  lookup_flow = {}

                  all_partitions = (0...partitions_count).to_a

                  # Filter partitions
                  if search_criteria[:partitions].include?('all')
                    partitions = all_partitions
                  else
                    partitions = all_partitions & search_criteria[:partitions].map(&:to_i)
                    partitions = all_partitions if partitions.empty?
                  end

                  # Establish starting point
                  case search_criteria[:offset_type]
                  when 'latest'
                    start = (search_criteria[:messages] / partitions_count) * -1
                  when 'offset'
                    start = search_criteria[:offset]
                  when 'timestamp'
                    start = Time.at(search_criteria[:timestamp])
                  else
                    raise
                  end

                  per_partition = (search_criteria[:messages] / partitions_count)

                  per_partition_count = search_criteria[:messages] / partitions_count
                    Karafka::Pro::Iterator.new(
                      {
                        topic => partitions.map { |par| [par, start] }.to_h
                      }
                    )
                  iterator = case search_criteria[:offset_type]
                  when 'latest'
                    Karafka::Pro::Iterator.new(
                      {
                        topic => partitions.map { |par| [par, start] }.to_h
                      }
                    )
                  when 'offset'
                    Karafka::Pro::Iterator.new(
                      {
                        topic => partitions.map { |par| [par, start] }.to_h
                      }
                    )
                  when 'timestamp'
                    Karafka::Pro::Iterator.new(
                      {
                        topic => partitions.map { |par| [par, start] }.to_h
                      }
                    )
                  else
                    raise
                  end

                  partitions = {}
                  details = Hash.new { |h, k| h[k] = { first_offset: -1, last_offset: -1, checked: 0, matched: 0 } }
                  details[:totals] = { matched: 0, checked: 0 }

                  found = []
                  phrase = search_criteria[:phrase]

                  iterator.each do |msg|
                    details[:totals][:checked] += 1
                    partitions[msg.partition] ||= 0
                    partitions[msg.partition] += 1

                    if details[msg.partition][:first_offset] < 0
                      details[msg.partition][:first_offset] = msg.offset
                    end

                    details[msg.partition][:last_offset] = msg.offset
                    details[msg.partition][:checked] += 1

                    if msg.raw_payload.include?(phrase)
                      found << msg
                      details[msg.partition][:matched] += 1
                      details[:totals][:matched] += 1
                    end

                    msg.clean!

                    if details[:totals][:checked] >= search_criteria[:messages]
                      iterator.stop
                    end

                    next if partitions[msg.partition] < per_partition

                    iterator.stop_current_partition
                  end

                  details[:totals][:time_taken] = monotonic_now - t

                  [found.sort_by(&:timestamp).reverse, details]
                end
              end
            end
          end
        end
      end
    end
  end
end
