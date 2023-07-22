# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Lib
        # Namespace for all the types of pagination engines we want to support
        module Paginations
          # Abstraction on top of pagination, so we can alter pagination key and other things
          # for non-standard pagination views (non page based, etc)
          #
          # @note We do not use `_page` explicitly to indicate, that the page scope may not operate
          #   on numerable pages (1,2,3,4) but can operate on offsets or times, etc. `_offset` is
          #   more general and may refer to many types of pagination.
          class Base
            attr_reader :previous_offset, :current_offset, :next_offset

            # @return [Boolean] Should we show pagination at all
            def paginate?
              raise NotImplementedError, 'Implement in a subclass'
            end

            # @return [Boolean] Should first offset link be active. If false, the first offset link
            #   will be disabled
            def first_offset?
              raise NotImplementedError, 'Implement in a subclass'
            end

            # @return [String] first offset url value
            def first_offset
              raise NotImplementedError, 'Implement in a subclass'
            end

            # @return [Boolean] Should previous offset link be active. If false, the previous
            #   offset link will be disabled
            def previous_offset?
              raise NotImplementedError, 'Implement in a subclass'
            end

            # @return [Boolean] Should we show current offset. If false, the current offset link
            #   will not be visible at all. Useful for non-linear pagination.
            def current_offset?
              raise NotImplementedError, 'Implement in a subclass'
            end

            # @return [Boolean] Should we show next offset pagination. If false, next offset link
            #   will be disabled.
            def next_offset?
              raise NotImplementedError, 'Implement in a subclass'
            end

            # @return [String] the url offset key
            def offset_key
              raise NotImplementedError, 'Implement in a subclass'
            end
          end
        end
      end
    end
  end
end
