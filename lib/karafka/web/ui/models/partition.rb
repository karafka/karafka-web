# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Models
        # Single topic partition data representation model
        class Partition < Lib::HashProxy
          # @param args [Object] anything hash proxy accepts
          def initialize(*args)
            super

            # We initialize those here because we want to have them stored in the internal has
            # for sorting
            lag_hybrid
            lag_hybrid_d
          end

          # Because `lag_stored` is not available until first marking, we fallback to the lag
          #   value that may be behind but is always available until stored lag is available.
          # @return [Integer] hybrid log value
          def lag_hybrid
            self[:lag_hybrid] ||= lag_stored.negative? ? lag : lag_stored
          end

          # @return [Integer] hybrid log delta
          def lag_hybrid_d
            self[:lag_hybrid_d] ||= lag_stored.negative? ? lag_d : lag_stored_d
          end

          # @return [Symbol] one of three states in which LSO can be in the correlation to given
          #   partition in the context of a consumer group.
          #
          # @note States descriptions:
          #   - `:active` all good. No hanging transactions, processing is ok
          #   - `:at_risk` - there may be hanging transactions but they do not affect processing
          #     before being stuck. This means, that the transaction still may be finished
          #     without affecting the processing, hence not having any impact.
          #   - `:stopped` - we have reached a hanging LSO and we cannot move forward despite more
          #     data being available. Unless the hanging transaction is killed or it finishes,
          #     we will not move forward.
          def lso_risk_state
            # If last stable is falling behind the high watermark
            if ls_offset < hi_offset
              # But it is changing and moving fast enough, it does not mean it is stuck
              return :active if ls_offset_fd < ::Karafka::Web.config.ui.lso_threshold

              # If it is stuck but we still have work to do, this is not a tragic situation because
              # maybe it will unstuck before we reach it
              return :at_risk if (committed_offset || 0) < ls_offset

              # If it is not changing and falling behind high, it is stuck
              :stopped
            else
              :active
            end
          end
        end
      end
    end
  end
end
