# frozen_string_literal: true

# Extra methods for controller helpers
module ControllerHelper
  def body
    last_response.body
  end

  def topics_config
    ::Karafka::Web.config.topics
  end

  def response
    last_response
  end

  def support_message
    'Please help us'
  end

  def status
    response.status
  end

  def breadcrumbs
    '<ol class="breadcrumb">'
  end
end
