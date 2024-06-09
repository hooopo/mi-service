# frozen_string_literal: true

require "logger"

# Define your custom middleware
class RequestLogger < Faraday::Middleware
  def initialize(app, logger = nil)
    super(app)
    @logger = logger || Logger.new($stdout)
  end

  def call(env)
    # Log request details
    @logger.info "Request Method: #{env.method.upcase}"
    @logger.info "Request URL: #{env.url}"
    @logger.info "Request Headers: #{env.request_headers}"
    @logger.info "Request Body: #{env.body}"
    @logger.info "Request Params: #{env.params}"

    # Call the app
    @app.call(env).on_complete do |response_env|
      # Log response details if necessary
      @logger.info "Response Status: #{response_env.status}"
      @logger.info "Response Headers: #{response_env.response_headers}"
      @logger.info "Response Body: #{response_env.body}"
    end
  end
end
