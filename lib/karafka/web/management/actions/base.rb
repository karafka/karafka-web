# frozen_string_literal: true

module Karafka
  module Web
    module Management
      module Actions
        # Base class for all the commands that we use to manage
        class Base
          include ::Karafka::Helpers::Colorize

          private

          # @return [String] green colored word "successfully"
          def successfully
            green('successfully')
          end

          # @return [String] green colored word "already"
          def already
            green('already')
          end

          # @return [Array<String>] topics available in the cluster
          def existing_topics_names
            @existing_topics_names ||= ::Karafka::Admin
                                       .cluster_info
                                       .topics
                                       .map { |topic| topic[:topic_name] }
          end
        end
      end
    end
  end
end
