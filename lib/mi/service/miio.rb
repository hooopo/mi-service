# frozen_string_literal: true

require "base64"
require "openssl"
require "json"
require "zlib"
require "stringio"
require "securerandom"
require "digest"
require "faraday"

require_relative "../logger"
require_relative "../utils"

module Mi
  module Service
    class MiIO
      attr_reader :account, :debug

      DEFAULT_HEADERS = {
        "User-Agent": "iOS-14.4-6.0.103-iPhone12,3--D7744744F7AF32F0544445285880DD63E47D9BE9-8816080-84A3F44E137B71AE-iPhone",
        "x-xiaomi-protocal-flag-cli": "PROTOCAL-HTTP2"
      }.freeze

      def initialize(account, debug: false)
        @debug = debug
        @account = account
        @account.login("xiaomiio") if @account.info["xiaomiio"].nil?
      end

      def miot_action(did, iid, args)
        sid = "xiaomiio"
        ssecurity = account.info[sid][0]
        device_id = account.info["deviceId"]

        url = "https://api.io.mi.com/app/miotspec/action"

        data = { "params" => { did: String(did), siid: Integer(iid[0]), aiid: Integer(iid[1]), in: Array(args) } }

        signed_data = self.class.sign_data("/miotspec/action", data, ssecurity)

        client = Faraday.new(url) do |f|
          f.response :logger if debug
          f.request :url_encoded
          f.headers = DEFAULT_HEADERS.merge(
            "Cookie" => Mi::Utils.cookie2str(
              account.auth_cookies(sid).merge("PassportDeviceId" => device_id)
            )
          )
        end
        response = client.post(url, signed_data)
        result = JSON.parse(response.body)
        result["message"] == "ok"
      end

      def self.sign_nonce(ssecurity, nonce)
        digest = OpenSSL::Digest.new("SHA256")
        digest.update(Base64.decode64(ssecurity))
        digest.update(Base64.decode64(nonce))
        Base64.strict_encode64(digest.digest)
      end

      def self.sign_data(uri, data, ssecurity)
        data = data.to_json unless data.is_a?(String)

        nonce = Base64.strict_encode64(OpenSSL::Random.random_bytes(8) + [Time.now.to_i / 60].pack("N"))
        snonce = sign_nonce(ssecurity, nonce)

        msg = [uri, snonce, nonce, "data=#{data}"].join("&")
        sign = OpenSSL::HMAC.digest("SHA256", Base64.decode64(snonce), msg)

        {
          "_nonce" => nonce,
          "data" => data,
          "signature" => Base64.strict_encode64(sign)
        }
      end
    end
  end
end
