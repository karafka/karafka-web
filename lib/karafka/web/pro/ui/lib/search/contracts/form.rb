# frozen_string_literal: true

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
                configure

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
                # - latest means we move back the needed per partition number of messages and we look
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

                  val.all? { |ar_val| ar_val.is_a?(String) }
                end
              end
            end
          end
        end
      end
    end
  end
end
