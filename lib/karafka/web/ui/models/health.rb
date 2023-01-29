# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Aggregated health data statistics representation
        class Health
          class << self
            # @param state [State] current system state
            # @return [Hash] has with aggregated statistics
            def current(state)
              stats = {}

              processes = Processes.active(state)

              processes.each do |process|
                process.consumer_groups.each do |details|
                  name = details.id

                  stats[name] ||= {}

                  details.topics.each do |details2|
                    t_name = details2.name

                    stats[name][t_name] ||= {}
                    details2.partitions.each do |partition|
                      partition_id = partition.id
                      stats[name][t_name] ||= {}
                      stats[name][t_name][partition_id] = partition.to_h
                      stats[name][t_name][partition_id][:process] = process
                    end
                  end
                end
              end

              stats
            end
          end
        end
      end
    end
  end
end
