# frozen_string_literal: true

# Checks every page rendered in the controllers specs that has navigation tabs: the breadcrumbs
# have to link the page of the active tab, so they always tell which tab page is displayed.
# The link does not have to be the last breadcrumb, as some pages add more after it (a schedule
# name, a command offset).
class BreadcrumbsValidator
  include Singleton

  # Tab links of the UX components showcase that do not lead to any page
  EXCLUDED_TAB_HREFS = [/\A#/].freeze

  # @param context [Minitest::Test] spec that rendered the page, used to fail it
  # @param body [String] rendered page
  def validate!(context, body)
    active = active_tab_paths(body)

    return if active.empty?

    crumbs = breadcrumb_paths(body)

    # Pages may disable breadcrumbs altogether
    return if crumbs.nil?

    active.each do |path|
      next if crumbs.include?(path)

      context.flunk(
        "The active tab links #{path} but no breadcrumb does. Breadcrumbs link: #{crumbs.inspect}"
      )
    end
  end

  private

  # @param body [String]
  # @return [Array<String>] paths of the active navigation tabs
  def active_tab_paths(body)
    body.scan(/<a\b([^>]*)>/m).flatten.filter_map do |attributes|
      classes = attributes[/class="([^"]*)"/m, 1].to_s.split

      next unless classes.include?("custom-tab") && classes.include?("active")

      href = attributes[/href="([^"]*)"/m, 1]

      next unless href
      next if EXCLUDED_TAB_HREFS.any? { |excluded| excluded.match?(href) }

      normalize(href)
    end
  end

  # @param body [String]
  # @return [Array<String>, nil] paths the breadcrumbs link or nil when there are no breadcrumbs
  def breadcrumb_paths(body)
    crumbs = body[%r{<div class="breadcrumbs">(.*?)</div>}m, 1]

    return nil unless crumbs

    crumbs.scan(/<a\b[^>]*href="([^"]*)"/m).flatten.map { |href| normalize(href) }
  end

  # Tabs and breadcrumbs may differ in the query (sorting, filtering, pages) and escaping only
  # @param href [String]
  # @return [String] path without query and fragment
  def normalize(href)
    CGI.unescapeHTML(href).split(/[?#]/).first.to_s
  end
end
