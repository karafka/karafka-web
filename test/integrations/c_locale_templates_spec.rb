# frozen_string_literal: true

# Verifies that the Web UI reads its templates as UTF-8 when the process runs under a C/POSIX
# locale (`LANG=C`, common in slim Docker images). There Ruby's default external encoding is
# US-ASCII, and a template with a non-ASCII byte must still render instead of returning 500.
#
# Run it with `LANG=C LC_ALL=C`.

require "bundler/setup"
require "karafka/web"
require "rack/mock"
require_relative "helper"

include IntegrationHelper

assert_equal(
  Encoding::US_ASCII,
  Encoding.default_external,
  "Run this scenario under a C locale (LANG=C LC_ALL=C)"
)

template_opts = Karafka::Web::Ui::App.opts[:render][:template_opts]

assert_equal(Encoding::UTF_8, template_opts[:default_encoding], "Templates should be read as UTF-8")

# Pro views too: the Pro app inherits these options from the shared base, and Pro itself needs
# a license to load
Dir[Karafka::Web.gem_root.join("lib/karafka/web/**/views/**/*.erb")].each do |path|
  template = Tilt.new(path, template_opts)

  assert_equal(Encoding::UTF_8, template.data.encoding, "#{path} should be read as UTF-8")
  assert(template.data.valid_encoding?, "#{path} should be valid UTF-8")
end

# The only view with non-ASCII characters today, rendered through the whole app
Karafka::Web.setup do |config|
  config.ui.sessions.secret = SecureRandom.hex(64)
end

status, _headers, body = Karafka::Web::Ui::App.call(Rack::MockRequest.env_for("/ux"))
html = +""
body.each { |chunk| html << chunk }

assert_equal(200, status, "GET /ux should render under a C locale")
pagination_rendered = html.force_encoding(Encoding::UTF_8).include?("Next ›")

assert(pagination_rendered, "GET /ux should render the pagination")

puts "C locale templates: OK"
