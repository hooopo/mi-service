# frozen_string_literal: true

require "securerandom"

module Mi
  module Utils
    def self.get_random(length)
      SecureRandom.alphanumeric(length)
    end

    def self.cookie2str(cookies)
      cookies.map { |k, v| "#{k}=#{v}" }.join("; ")
    end
  end
end
