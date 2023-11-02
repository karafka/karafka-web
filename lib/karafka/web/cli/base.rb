# frozen_string_literal: true

module Karafka
  module Web
    class Cli
      # Base command for all the Web Cli commands
      class Base < Karafka::Cli::Base
        include ::Karafka::Helpers::Colorize

        class << self
          # @return [Array<Class>] available commands
          def commands
            ObjectSpace
              .each_object(Class)
              .select { |klass| klass.superclass == Karafka::Web::Cli::Base }
              .reject { |klass| klass.to_s.end_with?('::Base') }
              .sort_by(&:name)
          end
        end

        private

        # Takes the CLI user provided replication factor but if not present, uses the brokers count
        # to decide. For non-dev clusters (with one broker) we usually want to have replication of
        # two, just to have some redundancy.
        # @param cli_replication_factor [Integer, false] user requested replication factor or false
        #   if we are supposed to compute the factor automatically
        # @return [Integer] replication factor for Karafka Web UI topics
        def compute_replication_factor(cli_replication_factor)
          cli_replication_factor || (Ui::Models::ClusterInfo.fetch.brokers.size > 1 ? 2 : 1)
        end
      end
    end
  end
end
