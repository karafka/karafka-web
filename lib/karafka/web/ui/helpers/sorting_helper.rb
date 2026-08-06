# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Helpers
        # Helpers for rendering sortable column links in data tables
        module SortingHelper
          # Default attribute names mapped from the attributes themselves
          # It makes it easier as we do not have to declare those all the time
          SORT_NAMES = {
            id: "ID",
            partition_id: "Partition",
            memory_usage: "RSS",
            started_at: "Started",
            committed_offset: "Committed",
            last_offset: "Last",
            first_offset: "First",
            lo_offset: "Low",
            hi_offset: "High",
            ls_offset: "LSO",
            lag_hybrid: "Lag",
            lag_stored: "Stored",
            stored_offset: "Stored",
            fetch_state: "Fetch",
            poll_state: "Poll",
            lso_risk_state: "LSO"
          }.freeze

          private_constant :SORT_NAMES

          # @param name [String] link value
          # @param attribute [Symbol, nil] sorting attribute or nil if we provide only symbol name
          # @param rev [Boolean] when set to true, arrows will be in the reverse position. This is
          #   used when the description in the link is reverse to data we sort. For example we have
          #   order on when processes were started and we display "x hours" ago but we sort on
          #   their age, meaning that it looks like it is the other way around. This flag allows
          #   us to reverse just he arrow making it look consistent with the presented data order
          # @return [String] html link for sorting with arrow when attribute sort enabled
          def sort_link(name, attribute = nil, rev: false)
            unless attribute
              attribute = name

              if SORT_NAMES[attribute]
                name = SORT_NAMES[attribute]
              else
                name = attribute.to_s.tr("_", " ").tr("?", "")
                # Always capitalize the name
                name = name.split.map(&:capitalize).join(" ")
              end
            end

            arrow_both = "&#x21D5;"
            arrow_down = "&#9662;"
            arrow_up = "&#9652;"

            desc = "#{attribute} desc"
            asc = "#{attribute} asc"
            path = current_path(sort: desc)
            full_name = "#{name}&nbsp;#{arrow_both}"

            if params.current_sort == desc
              path = current_path(sort: asc)
              full_name = "#{name}&nbsp;#{rev ? arrow_up : arrow_down}"
            end

            if params.current_sort == asc
              path = current_path(sort: desc)
              full_name = "#{name}&nbsp;#{rev ? arrow_down : arrow_up}"
            end

            "<a class=\"sort\" href=\"#{path}\">#{full_name}</a>"
          end
        end
      end
    end
  end
end
