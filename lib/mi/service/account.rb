# frozen_string_literal: true

require "securerandom"
require "digest"
require "faraday"
require "json"
require "base64"

require_relative "../logger"

module Mi
  module Service
    class Account
      attr_reader :userid, :password, :info, :debug

      DEFAULT_COOKIES = {
        "sdkVersion" => "3.9",
        "uLocale" => "zh_CN"
      }.freeze

      DEFAULT_HEADERS = {
        "User-Agent" => "APP/com.xiaomi.mihome APPV/6.0.103 iosPassportSDK/3.9.0 iOS/14.4 miHSTS"
      }.freeze

      def initialize(userid, password, debug: false)
        @userid = userid
        @password = password
        @debug = debug
        @success = false
        @info = {}
      end

      def login(sid)
        device_id = get_random(16).upcase
        cookies = DEFAULT_COOKIES.merge({
                                          "deviceId" => device_id
                                        })

        headers = DEFAULT_HEADERS.merge({
                                          "Cookie" => cookie2str(cookies)
                                        })
        client = Faraday.new do |faraday|
          faraday.response :logger if debug
          faraday.headers = headers
        end
        response = client.get(
          "https://account.xiaomi.com/pass/serviceLogin?sid=#{sid}&_json=true"
        )

        response_json = JSON.parse(response.body.sub("&&&START&&&", ""))
        return unless response_json["code"] != 0

        data = {
          _json: "true",
          qs: response_json["qs"],
          sid: response_json["sid"],
          _sign: response_json["_sign"],
          callback: response_json["callback"],
          user: userid,
          hash: md5_hash(password)
        }
        response2 = service_login(data, sid)
        response2_json = JSON.parse(response2.body.sub("&&&START&&&", ""))
        if (response2_json["code"]).zero?
          @info = response2_json.slice("userId", "passToken")
          @info["deviceId"] = device_id

          response3 = security_token_service(response2_json["location"], response2_json["nonce"],
                                             response2_json["ssecurity"])
          if response3.body == "ok"
            info[sid] = [response2_json["ssecurity"], response3.headers["set-cookie"][/serviceToken=([^;]+)/, 1]]
            @success = true
          else
            @success = false
          end
        else
          @success = false
        end
      end

      def service_login(data, _sid)
        cookies = DEFAULT_COOKIES.merge({
                                          "userId" => info["userId"],
                                          "passToken" => info["passToken"]
                                        })
        headers = DEFAULT_HEADERS.merge({
                                          "Cookie" => cookie2str(cookies),
                                          "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8"
                                        })
        client = Faraday.new do |faraday|
          faraday.request :url_encoded
          faraday.headers = headers
          faraday.use RequestLogger if debug
        end
        client.post(
          "https://account.xiaomi.com/pass/serviceLoginAuth2",
          data
        )
      end

      def security_token_service(location, nonce, ssecurity)
        cookies = DEFAULT_COOKIES
        headers = DEFAULT_HEADERS.merge({
                                          "Cookie" => cookie2str(cookies)
                                        })
        nsec = "nonce=#{nonce}&#{ssecurity}"
        client_sign = Base64.encode64(Digest::SHA1.digest(nsec)).chomp

        new_url = "#{location}&clientSign=#{URI.encode_uri_component(client_sign)}"
        client = Faraday.new do |faraday|
          faraday.headers = headers
          faraday.response :logger if debug
        end
        response = client.get(new_url)
        service_token = response.headers["set-cookie"][/serviceToken=([^;]+)/, 1]
        info["serviceToken"] = service_token
        response
      end

      def success?
        @success
      end

      private

      def get_random(length)
        SecureRandom.alphanumeric(length)
      end

      def md5_hash(string)
        Digest::MD5.hexdigest(string).upcase
      end

      def cookie2str(cookies)
        cookies.map { |k, v| "#{k}=#{v}" }.join("; ")
      end
    end
  end
end
