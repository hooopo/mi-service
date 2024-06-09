# frozen_string_literal: true

require "logger"

class RequestLogger < Faraday::Middleware
  def initialize(app, logger = nil)
    super(app)
    @logger = logger || Logger.new($stdout)
  end

  def call(env)
    @logger.info "Request Method: #{env.method.upcase}"
    @logger.info "Request URL: #{env.url}"
    @logger.info "Request Headers: #{env.request_headers}"
    @logger.info "Request Body: #{env.body}"
    @logger.info "Request Params: #{env.params}"

    @app.call(env).on_complete do |response_env|
      @logger.info "Response Status: #{response_env.status}"
      @logger.info "Response Headers: #{response_env.response_headers}"
      @logger.info "Response Body: #{response_env.body}"
    end
  end
end
