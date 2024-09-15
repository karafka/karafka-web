# frozen_string_literal: true

module Karafka
  module Web
    module Ui
      module Helpers
        # Helper for generating tailwind rendering components with Ruby
        # Simplifies many places in the UI
        module TailwindHelper
          # style types of components we support
          TYPES = %i[
            info
            error
            warning
            success
            primary
            secondary
          ].freeze

          # @return [Array<Symbol>] style types of components we support
          def tailwind_types
            TYPES
          end

          # Renders a plain badge
          # @param content [String] badge content
          # @param classes [String] extra css classes
          # @return [String] badge html
          def badge(content, classes: '')
            %(<span class="badge #{classes}">#{content}</span>)
          end

          # Renders a link to with button styling
          # @param name [String] button name
          # @param path [String] path to where to go
          # @param classes [String] extra css classes
          # @param title [String, nil] title (if any)
          # @return [String] button link html
          def link_button(name, path, classes: '', title: nil)
            %(<a href="#{path}" class="btn #{classes}" title="#{title}">#{name}</a>)
          end

          # Defines various methods for badges and links that simplify defining them without
          # having to provide whole classes scopes always.
          TYPES.each do |type|
            define_method :"badge_#{type}" do |content, classes: ''|
              badge(content, classes: "#{classes} badge-#{type}")
            end

            define_method :"badge_#{type}_sm" do |content, classes: ''|
              badge(content, classes: "#{classes} badge-#{type} badge-sm")
            end

            define_method :"link_button_#{type}" do |name, path, classes: ''|
              link_button(name, path, classes: "#{classes} btn-#{type}")
            end

            define_method :"link_button_#{type}_sm" do |name, path, classes: '', title: nil|
              link_button(name, path, classes: "#{classes} btn-#{type} btn-sm", title: title)
            end

            # @param message [String] alert message
            # @return [String] html with alert
            define_method :"alert_#{type}" do |message|
              partial(
                "shared/alerts/#{type}",
                locals: {
                  message: message
                }
              )
            end

            # @param message [String] alert message
            # @return [String] html with alert
            define_method :"alert_box_#{type}" do |title, description = nil, &block|
              description = capture_erb(&block) if block

              inject_erb partial(
                "shared/alerts/box_#{type}",
                locals: {
                  title: title,
                  description: description
                }
              )
            end
          end
        end
      end
    end
  end
end
