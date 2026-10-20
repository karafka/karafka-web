# frozen_string_literal: true

module Karafka
  module Web
    module Processing
      module Consumers
        module Contracts
          # Contract used to validate consumers reports when we ingest them.
          #
          # Reports may come from processes that do not run the Ruby tracking (for example apps
          # on librdkafka bindings in other languages), so unlike the sender side
          # `Tracking::Consumers::Contracts::Report`, it does not check Ruby-only values (Ruby
          # classes, Karafka status names). It requires the process, versions and stats fields and
          # the consumer groups tree and jobs keys that the processing and the Web UI read.
          class Report < Web::Contracts::Base
            # Is the value a Hash with Hash values
            HASH_OF_HASHES = ->(val) { val.is_a?(Hash) && val.values.all?(Hash) }

            # Subscription group state keys the UI reads, by their expected type
            SG_STATE_KEYS = {
              String => %i[join_state rebalance_reason],
              Integer => %i[stateage rebalance_age rebalance_cnt poll_age]
            }.freeze

            # Partition keys the UI reads, by their expected type
            PARTITION_KEYS = {
              String => %i[fetch_state poll_state],
              Integer => %i[
                id lag lag_d lag_stored lag_stored_d committed_offset stored_offset hi_offset
                ls_offset ls_offset_fd poll_state_ch
              ]
            }.freeze

            # Are all the given keys of the hash of the expected types
            TYPED = lambda do |hash, keys|
              keys.all? { |type, names| names.all? { |name| hash[name].is_a?(type) } }
            end

            private_constant :HASH_OF_HASHES, :SG_STATE_KEYS, :PARTITION_KEYS, :TYPED

            configure

            required(:schema_version) { |val| val.is_a?(String) && !val.empty? }
            required(:dispatched_at) { |val| val.is_a?(Numeric) && val.positive? }
            required(:type) { |val| val == "consumer" }

            nested(:process) do
              required(:started_at) { |val| val.is_a?(Numeric) && val.positive? }
              required(:id) { |val| val.is_a?(String) && !val.empty? }
              required(:cpus) { |val| val.is_a?(Integer) && val >= 1 }
              required(:memory_usage) { |val| val.is_a?(Integer) && val >= 0 }
              required(:memory_total_usage) { |val| val.is_a?(Integer) && val >= 0 }
              required(:memory_size) { |val| val.is_a?(Integer) && val >= 0 }
              required(:status) { |val| val.is_a?(String) && !val.empty? }
              required(:threads) { |val| val.is_a?(Integer) && val >= 0 }
              required(:workers) { |val| val.is_a?(Integer) && val >= 0 }
              required(:tags) { |val| val.is_a?(Array) && val.all?(String) }
              required(:execution_mode) { |val| val.is_a?(String) && !val.empty? }

              nested(:listeners) do
                required(:active) { |val| val.is_a?(Integer) && val >= 0 }
                required(:standby) { |val| val.is_a?(Integer) && val >= 0 }
              end

              required(:cpu_usage) do |val|
                val.is_a?(Array) && val.size == 3 && val.all?(Numeric)
              end
            end

            nested(:versions) do
              required(:ruby) { |val| val.is_a?(String) }
              required(:karafka) { |val| val.is_a?(String) }
              required(:karafka_core) { |val| val.is_a?(String) }
              required(:karafka_web) { |val| val.is_a?(String) }
              required(:waterdrop) { |val| val.is_a?(String) }
              required(:rdkafka) { |val| val.is_a?(String) }
              required(:librdkafka) { |val| val.is_a?(String) }
            end

            nested(:stats) do
              required(:busy) { |val| val.is_a?(Integer) && val >= 0 }
              required(:enqueued) { |val| val.is_a?(Integer) && val >= 0 }
              required(:waiting) { |val| val.is_a?(Integer) && val >= 0 }
              required(:utilization) { |val| val.is_a?(Numeric) && val >= 0 }

              nested(:total) do
                required(:jobs) { |val| val.is_a?(Integer) && val >= 0 }
                required(:batches) { |val| val.is_a?(Integer) && val >= 0 }
                required(:messages) { |val| val.is_a?(Integer) && val >= 0 }
                required(:errors) { |val| val.is_a?(Integer) && val >= 0 }
                required(:retries) { |val| val.is_a?(Integer) && val >= 0 }
                required(:dead) { |val| val.is_a?(Integer) && val >= 0 }
              end
            end

            required(:consumer_groups) { |val| HASH_OF_HASHES.call(val) }
            required(:jobs) { |val| val.is_a?(Array) && val.all?(Hash) }

            # Checks the consumer groups tree down to the partitions. Without these keys the UI
            # fails or `HashProxy` renders a same-named nested value instead.
            virtual do |data, errors|
              next unless errors.empty?

              valid = data.fetch(:consumer_groups).each_value.all? do |cg|
                cg[:id].is_a?(String) &&
                  HASH_OF_HASHES.call(cg[:subscription_groups]) &&
                  cg[:subscription_groups].each_value.all? do |sg|
                    sg[:id].is_a?(String) &&
                      (sg[:instance_id] == false || sg[:instance_id].is_a?(String)) &&
                      sg[:state].is_a?(Hash) &&
                      TYPED.call(sg[:state], SG_STATE_KEYS) &&
                      HASH_OF_HASHES.call(sg[:topics]) &&
                      sg[:topics].each_value.all? do |topic|
                        topic[:name].is_a?(String) &&
                          topic[:partitions_cnt].is_a?(Integer) &&
                          HASH_OF_HASHES.call(topic[:partitions]) &&
                          topic[:partitions].each_value.all? do |partition|
                            TYPED.call(partition, PARTITION_KEYS)
                          end
                      end
                  end
              end

              valid ? nil : [[%i[consumer_groups], :format]]
            end

            # Checks the jobs keys the jobs views read
            virtual do |data, errors|
              next unless errors.empty?

              valid = data.fetch(:jobs).all? do |job|
                job[:consumer].is_a?(String) &&
                  job[:consumer_group].is_a?(String) &&
                  job[:topic].is_a?(String) &&
                  job[:partition].is_a?(Integer) &&
                  job[:first_offset].is_a?(Integer) &&
                  job[:updated_at].is_a?(Numeric) &&
                  job[:status].is_a?(String)
              end

              valid ? nil : [[%i[jobs], :format]]
            end
          end
        end
      end
    end
  end
end
