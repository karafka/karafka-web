# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Helpers
        # Kafka partition presentation helpers: replica/ISR broker ids, LSO risk state and
        # offset/lag labels
        module PartitionsHelper
          # Renders the assigned replica broker ids for a partition as badges. The leader is
          # emphasized and any replica that is not part of the in-sync set (ISR) is highlighted
          # as a warning, turning the replication view into an at-a-glance health signal.
          #
          # @param partition [Hash, Ui::Models::Partition] partition metadata
          # @param link [Boolean] when true, each broker badge links to its broker details page
          #   (Pro-only; OSS has no per-broker view so it renders plain badges)
          # @return [String] replica broker ids as badges with a count subtext
          def partition_replica_brokers(partition, link: false)
            replicas = partition[:replicas]

            return %(<span class="text-muted">&mdash;</span>) if replicas.empty?

            leader = partition[:leader]
            isrs = partition[:isrs]

            badges = replicas.map do |broker_id|
              css = if broker_id == leader
                "badge-primary"
              elsif isrs.include?(broker_id)
                "badge-info"
              else
                "badge-warning"
              end

              broker_id_badge(broker_id, css, link: link)
            end.join(" ")

            "#{badges}#{broker_count_note(replicas.size, "replicas")}"
          end

          # Renders the in-sync (ISR) broker ids for a partition as badges, with the leader
          # emphasized. An empty ISR set (fully under-replicated partition) renders a dash.
          #
          # @param partition [Hash, Ui::Models::Partition] partition metadata
          # @param link [Boolean] when true, each broker badge links to its broker details page
          #   (Pro-only; OSS has no per-broker view so it renders plain badges)
          # @return [String] in-sync broker ids as badges with a count subtext
          def partition_in_sync_brokers(partition, link: false)
            isrs = partition[:isrs]

            return %(<span class="text-muted">&mdash;</span>) if isrs.empty?

            leader = partition[:leader]

            badges = isrs.map do |broker_id|
              css = (broker_id == leader) ? "badge-primary" : "badge-success"

              broker_id_badge(broker_id, css, link: link)
            end.join(" ")

            "#{badges}#{broker_count_note(isrs.size, "in-sync")}"
          end

          # @param details [::Karafka::Web::Ui::Models::Partition] partition information with
          #   lso risk state info
          # @return [String] background classes for row marking
          def lso_risk_state_bg(details)
            case details.lso_risk_state
            when :active
              ""
            when :at_risk
              "bg-warning bg-opacity-25"
            when :stopped
              "bg-error bg-opacity-25"
            else
              raise ::Karafka::Errors::UnsupportedCaseError
            end
          end

          # @param details [::Karafka::Web::Ui::Models::Partition] partition information with
          #   lso risk state info
          # @return [String] the full daisyUI badge color class for the state. Callers should use
          #   this alone (e.g. `class="badge #{lso_risk_state_badge(details)}"`) rather than adding
          #   their own `badge-success`, otherwise `at_risk`/`stopped` end up with two colliding
          #   color classes.
          def lso_risk_state_badge(details)
            case details.lso_risk_state
            when :active
              "badge-success"
            when :at_risk
              "badge-warning"
            when :stopped
              "badge-error"
            else
              raise ::Karafka::Errors::UnsupportedCaseError
            end
          end

          # Classifies a lag value against the configured high-lag threshold, for at-a-glance row
          # highlighting. The threshold marks an error; half of it marks a warning.
          #
          # @param lag [Integer] a lag value (a partition's lag, or a topic's average partition lag)
          # @return [Symbol, nil] `:error`, `:warning` or nil (nil also for N/A / negative lags)
          def lag_severity(lag)
            return nil if lag.negative?

            threshold = ::Karafka::Web.config.ui.health.lags.high_threshold

            return :error if lag >= threshold
            return :warning if lag >= threshold / 2

            nil
          end

          # `status-row-*` class for a row based purely on a lag value (used where there is no other
          # per-row status, e.g. cluster lag partitions).
          #
          # @param lag [Integer] lag value to classify
          # @param fallback [String] class to use when the lag is not high enough to highlight
          # @return [String] `status-row-error`/`status-row-warning`, or the fallback
          def lag_status_row(lag, fallback = "")
            severity = lag_severity(lag)

            severity ? "status-row-#{severity}" : fallback
          end

          # `status-row-*` class for an aggregated topic row. High lag wins, but a skewed topic is
          # also surfaced as a warning even when its average lag is not high on its own.
          #
          # @param topic_stats [#avg_lag, #skewed?] an aggregated topic row (report or cluster)
          # @return [String] `status-row-error`/`status-row-warning`, or an empty string
          def topic_lag_status_row(topic_stats)
            severity = lag_severity(topic_stats.avg_lag)
            severity ||= :warning if topic_stats.skewed?

            severity ? "status-row-#{severity}" : ""
          end

          # @param lag [Integer] lag
          # @return [String] lag if correct or `N/A` with labeled explanation
          # @see #offset_with_label
          def lag_with_label(lag)
            if lag.negative?
              title = "Not available until first offset commit"
              %(<span class="badge badge-secondary" title="#{title}">N/A</span>)
            else
              lag.to_s
            end
          end

          # @param topic_name [String] name of the topic for explorer path
          # @param partition_id [Integer] partition for the explorer path
          # @param offset [Integer] offset
          # @param explore [Boolean] should we generate (when allowed) a link to message explorer
          # @return [String] offset if correct or `N/A` with labeled explanation for offsets
          #   that are less than 0. Offset with less than 0 indicates, that the offset was not
          #   yet committed and there is no value we know of
          def offset_with_label(topic_name, partition_id, offset, explore: false)
            if offset.negative?
              title = "Not available until first offset commit"
              %(<span class="badge badge-secondary" title="#{title}">N/A</span>)
            elsif explore
              path = explorer_topics_path(topic_name, partition_id, offset)
              %(<a href="#{path}">#{offset}</a>)
            else
              offset.to_s
            end
          end

          # Normalizes the metric value for display. Negative values coming from statistics usually
          #   mean, that the value is not (yet) available.
          #
          # @param value [Integer]
          # @return [String] input value if not negative or N/A
          def normalized_metric(value)
            value.negative? ? "N/A" : value.to_s
          end

          private

          # Renders the small muted "N replicas" / "N in-sync" summary shown under the broker
          # badges. Kept next to the badge rendering so the count is never duplicated with the
          # numeric fallback used for older karafka-rdkafka.
          #
          # @param count [Integer] number of brokers
          # @param label [String] summary label (e.g. "replicas", "in-sync")
          # @return [String] count subtext html
          def broker_count_note(count, label)
            %(<div><small class="text-muted">#{count} #{label}</small></div>)
          end

          # Renders a single broker id badge, optionally wrapped in a link to the broker details
          # page. Linking is Pro-only (OSS has no per-broker view), so it is opt-in via `link`.
          #
          # @param broker_id [Integer] broker id
          # @param css [String] badge style class
          # @param link [Boolean] whether to link the badge to the broker details page
          # @return [String] badge html (optionally linked)
          def broker_id_badge(broker_id, css, link:)
            badge = %(<span class="badge #{css}">#{broker_id}</span>)

            return badge unless link

            %(<a href="#{root_path("cluster", broker_id)}" title="Broker #{broker_id} details">#{badge}</a>)
          end
        end
      end
    end
  end
end
