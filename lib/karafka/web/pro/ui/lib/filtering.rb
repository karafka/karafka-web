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
      module Ui
        module Lib
          # Filtering (search) is a Pro-only feature, so all of its wiring lives in this concern and
          # is mixed only into Pro controllers. OSS controllers never gain filtering.
          #
          # It is included by the Pro base controller (covering every standalone Pro controller) and,
          # because a few Pro controllers inherit OSS controllers directly (and thus bypass the Pro
          # base controller), by those explicitly.
          module Filtering
            # @param base [Class] the controller including this concern
            def self.included(base)
              # Attributes on which we can filter in a given controller. Since we can filter on
              # method invocations, this needs to be limited and provided on a per controller basis
              # (same contract as `sortable_attributes`).
              #
              # It is either a flat list applied to every action, or a `{ action => fields }` hash
              # with an optional `:default` entry for controllers whose actions render different
              # columns (e.g. cluster brokers vs configs). See {#filterable_fields} for the
              # resolution.
              base.singleton_class.attr_accessor :filterable_attributes

              # Expose the per-action filterable fields to the view so the filtering box (and the
              # view-level filtering helpers) can render the field selector. Resolved from the
              # controller's `filterable_attributes` declaration on every request, so no action has
              # to wire this up by hand.
              base.before { @filterable_fields = filterable_fields }
            end

            private

            # Filters the provided resources in place based on the current filtering keyword and the
            # fields allowed for filtering.
            #
            # The allowed fields default to `@filterable_fields`, which the before hook resolves from
            # the controller's `filterable_attributes` declaration for the current action and exposes
            # to the view. Pass `fields` only when the engine's match set must differ from the fields
            # shown in the selector (e.g. the health views scope the selector by topic/consumer group
            # but keyword-match against the leaf partition id); it overrides matching only and does
            # not change the exposed selector.
            #
            # @param resources [Hash, Array, Web::Ui::Lib::HashProxy] object for filtering
            # @param fields [Array<Symbol>, nil] explicit engine allow-list for matching, overriding
            #   `@filterable_fields`
            # @return [Hash, Array, Web::Ui::Lib::HashProxy] filtered results
            # @note It mutates the provided resources in place, so it must not be used on shared
            #   structures like the app routing.
            def filter(resources, fields: nil)
              Web::Ui::Lib::Filter.new(
                @params.current_filter,
                allowed_attributes: fields || @filterable_fields,
                field: @params.current_filter_field
              ).call(resources)
            end

            # Resolves the fields the current action can be filtered on from the controller's
            # `filterable_attributes` declaration. The declaration is either a flat list (applied to
            # every action) or a `{ action => fields }` hash with an optional `:default` entry used
            # for the actions not listed explicitly.
            #
            # @return [Array<Symbol>, Array<String>] fields for the current action (empty when the
            #   action is not filterable)
            def filterable_fields
              attributes = self.class.filterable_attributes

              return Array(attributes) unless attributes.is_a?(Hash)

              Array(attributes[@current_action_name] || attributes[:default])
            end
          end
        end
      end
    end
  end
end
