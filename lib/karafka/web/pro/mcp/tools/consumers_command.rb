# frozen_string_literal: true

# Karafka Pro - Source Available Commercial Software
# Copyright (c) 2017-present Maciej Mensfeld. All rights reserved.
#
# This software is NOT open source. It is source-available commercial software
# requiring a paid license for use. It is NOT covered by LGPL.
#
# The author retains all right, title, and interest in this software,
# including all copyrights, patents, and other intellectual property rights.
# No patent rights are granted under this license.
#
# PROHIBITED:
# - Use without a valid commercial license
# - Redistribution, modification, or derivative works without authorization
# - Reverse engineering, decompilation, or disassembly of this software
# - Use as training data for AI/ML models or inclusion in datasets
# - Scraping, crawling, or automated collection for any purpose
#
# PERMITTED:
# - Reading, referencing, and linking for personal or commercial use
# - Runtime retrieval by AI assistants, coding agents, and RAG systems
#   for the purpose of providing contextual help to Karafka users
#
# Receipt, viewing, or possession of this software does not convey or
# imply any license or right beyond those expressly stated above.
#
# License: https://karafka.io/docs/Pro-License-Comm/
# Contact: contact@karafka.io

module Karafka
  module Web
    module Pro
      module Mcp
        module Tools
          # Base for the tools that pause, resume or seek consumers, as the Web UI partition and
          # topic actions do. They build and send the same commands as those actions
          class ConsumersCommand < Base
            # Arguments that point to a consumer group topic
            TOPIC_PROPERTIES = {
              consumer_group_id: { type: "string", description: "Id of the consumer group" },
              topic: { type: "string", description: "Topic name" }
            }.freeze

            # Argument that points to a partition of the topic
            PARTITION_PROPERTIES = {
              partition: { type: "integer", minimum: 0, description: "Partition of the topic" }
            }.freeze

            # Arguments of the pause tools
            PAUSE_PROPERTIES = {
              duration: {
                type: "integer",
                minimum: 0,
                description: "Pause duration in seconds. 0 pauses until a resume"
              },
              prevent_override: {
                type: "boolean",
                description: "Keep a pause the consumer code set instead of replacing it"
              }
            }.freeze

            # Arguments of the resume tools
            RESUME_PROPERTIES = {
              reset_attempts: {
                type: "boolean",
                description: "Reset the retry attempts counter of the paused partitions"
              }
            }.freeze

            # @param arguments [Hash] tool arguments
            # @raise [Errors::Mcp::InvalidArgumentsError] when arguments do not pass the tool
            #   contract or the Web UI form contract
            def initialize(arguments)
              super
              @command = command
            end

            # Commanding must be enabled, as for the Web UI actions
            def authorize!
              deny!("Commanding is disabled") unless Ui::Lib::Features.commanding?
            end

            # @return [Array<String>] the commands topic
            def topics
              [::Karafka::Web.config.topics.consumers.commands.name]
            end

            private

            # @return [Hash] dispatched command
            def fetch
              change = plan

              Ui::Lib::Consumers::Commands::Dispatcher.new(@command).call

              { dispatched: true }.merge(change)
            end

            # @return [Hash] command the tool would send
            def plan
              ensure_target_exists!

              @command.slice(:name, :payload, :matchers)
            end

            # The Web UI actions answer 404 for a consumer group, topic or partition that the
            # consumers do not report, so we refuse them too
            #
            # @raise [Errors::Mcp::NoDataError] when the consumers do not report the target
            def ensure_target_exists!
              stats = Web::Ui::Models::Health.current(Web::Ui::Models::ConsumersState.current!)

              topic_stats = stats[target[:consumer_group_id]]&.dig(:topics, target[:topic])
              partition_id = target[:partition_id]

              found = if partition_id.nil?
                !topic_stats.nil?
              else
                !topic_stats&.dig(:partitions, partition_id).nil?
              end

              return if found

              raise Errors::Mcp::NoDataError, "Consumers do not report this consumer group, " \
                "topic or partition. Check karafka_health for what they consume"
            end

            # @return [String] Web UI path of the consumer group topic or partition
            def target_path
              segments = [target[:consumer_group_id], target[:topic], target[:partition_id]]

              (target.key?(:partition_id) ? "partitions/" : "topics/") + segments.compact.join("/")
            end

            # @return [Hash] command built from the arguments
            def command
              raise NotImplementedError, "Implement in a subclass"
            end

            # @param contract [Web::Contracts::Base] Web UI form contract
            # @param form [Hash] normalized Web UI form
            # @return [Hash] form when it passes the same checks as in the Web UI
            def validate(contract, form)
              errors = contract.new.call(form).errors

              return form if errors.empty?

              raise(
                Errors::Mcp::InvalidArgumentsError,
                errors.map { |key, message| "#{key} #{message}" }.join(", ")
              )
            end

            # @return [Hash] consumer group, topic and partition the command is for
            def target
              target = {
                consumer_group_id: @arguments.fetch(:consumer_group_id),
                topic: @arguments.fetch(:topic)
              }

              target[:partition_id] = @arguments[:partition] if @arguments.key?(:partition)
              target
            end

            # @return [Hash] Web UI pause form from the arguments
            def pause_form
              validate(
                Ui::Lib::Consumers::Commands::Contracts::Pause,
                Ui::Lib::Consumers::Commands::Normalizer.pause(
                  duration: @arguments.fetch(:duration).to_s,
                  prevent_override: @arguments[:prevent_override].to_s
                )
              ).merge(target)
            end

            # @return [Hash] Web UI resume form from the arguments
            def resume_form
              Ui::Lib::Consumers::Commands::Normalizer
                .resume(reset_attempts: @arguments[:reset_attempts].to_s)
                .merge(target)
            end
          end
        end
      end
    end
  end
end
