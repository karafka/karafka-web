# frozen_string_literal: true

module Karafka
  module Web
    module Tracking
      module Consumers
        module Listeners
          # Tracks data related to transactions
          # seek offsets are needed because when consumer offsets are committed in transactions,
          # librdkafka does not publish the lags in a regular way (they are set to -1) and we need
          # to compute them via enrichment of information.
          class Transactions < Base
            # Tracking of things needed to support transactional consumers post successful
            # transaction.
            #
            # @param event [Karafka::Core::Monitoring::Event]
            def on_consumer_consuming_transaction(event)
              consumer = event[:caller]
              sg_id = consumer.topic.subscription_group.id
              topic_name = consumer.topic.name
              # We store it as a string because librdkafka also does that and its easier to align
              # without casting it later
              partition_id = consumer.partition

              track do |sampler|
                break unless sampler.subscription_groups.key?(sg_id)

                seek_offset = consumer.coordinator.seek_offset

                break if seek_offset.nil?

                topics_scope = sampler.subscription_groups[sg_id][:topics]
                p_scope = topics_scope[topic_name][partition_id]

                p_scope[:transactional] = true
                p_scope[:seek_offset] = seek_offset
              end
            end
          end
        end
      end
    end
  end
end
