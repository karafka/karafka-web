# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Web
    module Pro
      module Ui
        module Lib
          module Search
            module Contracts
              # Validates the search input
              # This is not a complex validator with error handling, etc
              # Since we use HTML5 validations that are good enough, here we check all the
              # consistency of the data but without providing sophisticated user error reporting as
              # it is the final checking that should not happen often.
              #
              # @note This does not validate the raw input from the HTML but one that was slightly
              #   normalized to simplify the flow.
              class Form < Web::Contracts::Base
                configure do |config|
                  config.error_messages = YAML.safe_load_file(
                    File.join(Karafka::Web.gem_root, 'config', 'locales', 'pro_errors.yml')
                  ).fetch('en').fetch('validations').fetch('search_form')
                end

                # Minimum timestamp value when timestamps are used
                # 2001-09-09. This value selected because it is older than Kafka and it looks nice
                MIN_TIMESTAMP = 1_000_000_000

                private_constant :MIN_TIMESTAMP

                # What are we looking for
                required(:phrase) { |val| val.is_a?(String) && !val.empty? }

                # How many messages in total should we scan. In case of many partitions, this is
                # distributed evenly across them. So 100 000 in 5 partitions, means scanning
                # 20 000 per partition.
                required(:limit) do |val|
                  Web.config.ui.search.limits.include?(val)
                end

                # What matcher should we use when matching phrase and message
                # It allows only matchers that we have declared in search
                required(:matcher) do |val|
                  Web.config.ui.search.matchers.map(&:name).include?(val)
                end

                # Where should we start looking in the data
                # - latest means we move back the needed per partition number of messages
                #   and we look
                # - offset means we start from the same offset on all the partitions
                # - timestamp means we start from a given time moment on all the partitions
                required(:offset_type) { |val| %w[latest offset timestamp].include?(val) }

                # Offset from which to start. We can always require it even if we do not start from
                # a certain offset because we work on a normalized data
                required(:offset) { |val| val.is_a?(Integer) && val >= 0 }

                # Similar as above but for timestamp.
                required(:timestamp) do |val|
                  next false unless val.is_a?(Integer)
                  next false if val.negative?
                  next false if val > ((Time.now.to_f + 60) * 1_000).to_i

                  true
                end

                # We do not check here that partitions actually exist because when searching we just
                # reject non-existing partitions
                required(:partitions) do |val|
                  next false unless val.is_a?(Array)
                  next false if val.empty?

                  val.all?(String)
                end

                # Special validation for timestamp to make sure it is not older than 2010
                # Since Kafka is not that old, timestamps should never be less than that.
                # While all the others will use standard "is invalid" because they also have a
                # frontend HTML5 validation. This one is specific because we want to allow setting
                # 0 as long as we don't select the timestamp as a value. Then we want to make sure
                # that user provides the message timestamp which is in ms
                virtual do |data, errors|
                  next unless errors.empty?
                  # Validate only if we decide to go with timestamp. Otherwise this value is
                  # irrelevant
                  next unless data[:offset_type] == 'timestamp'

                  next if data[:timestamp] >= MIN_TIMESTAMP

                  [[%i[timestamp], :key_must_be_large_enough]]
                end
              end
            end
          end
        end
      end
    end
  end
end
