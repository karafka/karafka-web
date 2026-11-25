# frozen_string_literal: true

# Verifies that `nil` works as "not set" for the custom UI settings (`ui.custom.css`, `js` and
# `nav_erb`), as `false` does: `Karafka::Web.enable!` accepts the config and the Web UI renders
# without the custom assets.

require "bundler/setup"
require "securerandom"
require "karafka"
require "karafka/web"
require "rack/mock"
require_relative "helper"

include IntegrationHelper

class KarafkaApp < Karafka::App
  setup do |config|
    config.kafka = { "bootstrap.servers": ENV.fetch("KAFKA_BOOTSTRAP_SERVERS", "127.0.0.1:9092") }
    config.client_id = "it-nil-custom-settings-#{SecureRandom.hex(6)}"
  end
end

Karafka::Web.setup do |config|
  config.group_id = "it-nil-custom-settings-#{SecureRandom.hex(6)}"
  config.ui.sessions.secret = SecureRandom.hex(64)
  config.ui.custom.css = nil
  config.ui.custom.js = nil
  config.ui.custom.nav_erb = nil
end

Karafka::Web.enable!

def get(path)
  status, _headers, body = Karafka::Web::Ui::App.call(Rack::MockRequest.env_for(path))
  html = +""
  body.each { |chunk| html << chunk }
  [status, html]
end

status, html = get("/ux")

assert_equal(200, status, "GET /ux should render with nil custom settings")
assert_equal([], html.scan(/custom\.(?:css|js)/), "Layout should not link custom assets")

status, = get("/assets/#{Karafka::Web::VERSION}/stylesheets/custom.css")

assert_equal(404, status, "Custom CSS should not be served")

status, = get("/assets/#{Karafka::Web::VERSION}/javascripts/custom.js")

assert_equal(404, status, "Custom JS should not be served")

puts "Nil custom settings: OK"
