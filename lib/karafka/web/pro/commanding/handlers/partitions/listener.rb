# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Commanding
        module Handlers
          module Partitions
            class Listener
              def initialize
                tracker
              end

              def on_connection_listener_fetch_loop(event)
                client = event[:client]
                listener = event[:caller]

                tracker.each_for(listener.subscription_group.id) do |details|
                  topic = details.fetch(:topic)
                  partition_id = details.fetch(:partition_id)
                  coordinator = listener.coordinators.find_or_create(topic, partition_id)

                  if details[:name] == 'partitions.resume'
                    coordinator.pause_tracker.expire
                    coordinator.pause_tracker.reset if details[:reset_attempts]

                    dispatcher.result(
                      details.merge(status: 'applied'),
                      process_id,
                      'partitions.resume',
                    )
                  elsif details[:name] == 'partitions.pause'
                    if coordinator.pause_tracker.paused? && details[:prevent_override]
                      dispatcher.result(
                        details.merge(status: 'prevented'),
                        process_id,
                        'partitions.resume',
                      )

                      return
                    end

                    duration = details[:duration] * 1_000
                    duration = 10 * 365 * 24 * 60 * 60 * 1000 if duration.zero?

                    coordinator.pause_tracker.pause(duration)
                    client.pause(topic, partition_id, nil, duration)

                    dispatcher.result(
                      details.merge(status: 'applied'),
                      process_id,
                      'partitions.pause',
                    )
                  else
                    desired_offset = details.fetch(:offset)
                    prevent_overtaking = details.fetch(:prevent_overtaking)
                    force_resume = details.fetch(:force_resume)

                    if prevent_overtaking && coordinator.seek_offset
                      first_offset = coordinator.seek_offset

                      if first_offset >= desired_offset
                        dispatcher.result(
                          details.merge(status: 'prevented'),
                          process_id,
                          'partitions.seek'
                        )

                        return
                      end
                    end

                    if desired_offset >= 0
                      assigned = client.mark_as_consumed!(
                        Messages::Seek.new(topic, partition_id, desired_offset - 1)
                      )

                      unless assigned
                        dispatcher.result(
                          details.merge(status: 'lost_partition'),
                          process_id,
                          'partitions.seek'
                        )

                        return
                      end
                    end

                    client.seek(Messages::Seek.new(topic, partition_id, desired_offset))
                    coordinator.seek_offset = desired_offset
                    coordinator.pause_tracker.reset
                    coordinator.pause_tracker.expire if force_resume

                    dispatcher.result(
                      details.merge(status: 'applied'),
                      process_id,
                      'partitions.seek',
                    )
                  end
                end
              end

              # Creates a rebalance barrier, so we do not execute any commands in between
              # rebalances. This prevents us from aggregating old and outdated requests.
              def on_rebalance_partitions_assigned(event)
                tracker.each_for(event[:subscription_group_id]) do |details|
                  dispatcher.result(
                    details.merge(status: 'rebalance_rejected'),
                    process_id,
                    'partitions.seek'
                  )
                end
              end

              def on_rebalance_partitions_revoked(event)
                on_rebalance_partitions_assigned(event)
              end

              private

              def tracker
                Tracker.instance
              end

              def dispatcher
                Commanding::Dispatcher
              end

              def process_id
                ::Karafka::Web.config.tracking.consumers.sampler.process_id
              end
            end
          end
        end
      end
    end
  end
end
