# frozen_string_literal: true

require "securerandom"
require "digest"
require "faraday"
require "json"
require "base64"

require_relative "../logger"
require_relative "../utils"

module Mi
  module Service
    class Account
      attr_reader :userid, :password, :info, :debug, :notification_url

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
        device_id = @info["deviceId"] || Mi::Utils.get_random(16).upcase
        login_response = service_login(sid)

        unless (login_response["code"]).zero?
          data = {
            _json: "true",
            qs: login_response["qs"],
            sid: login_response["sid"],
            _sign: login_response["_sign"],
            callback: login_response["callback"],
            user: userid,
            hash: md5_hash(password)
          }
          login_response = service_login_auth2(data)
          if login_response["notificationUrl"]
            @notification_url = "https://account.xiaomi.com#{login_response["notificationUrl"]}"
            raise "Please verify your account by visiting #{@notification_url}"
          end
        end

        if (login_response["code"]).zero?
          @info = @info.merge login_response.slice("userId", "passToken")
          @info["deviceId"] = device_id

          security_token_service(
            sid,
            login_response["location"],
            login_response["nonce"],
            login_response["ssecurity"]
          )
        else
          @success = false
        end
      end

      def service_login(sid)
        cookies = DEFAULT_COOKIES
        if @info["passToken"]
          cookies = cookies.merge({ "userId" => @info["userId"],
                                    "passToken" => @info["passToken"] })
        end

        headers = DEFAULT_HEADERS.merge({
                                          "Cookie" => Mi::Utils.cookie2str(cookies)
                                        })
        client = Faraday.new do |faraday|
          faraday.headers = headers
          faraday.use RequestLogger if debug
        end
        response = client.get(
          "https://account.xiaomi.com/pass/serviceLogin?sid=#{sid}&_json=true"
        )
        JSON.parse(response.body.sub("&&&START&&&", ""))
      end

      def service_login_auth2(data)
        cookies = DEFAULT_COOKIES
        if @info["passToken"]
          cookies = cookies.merge({ "userId" => @info["userId"],
                                    "passToken" => @info["passToken"] })
        end

        headers = DEFAULT_HEADERS.merge({
                                          "Cookie" => Mi::Utils.cookie2str(cookies),
                                          "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8"
                                        })
        client = Faraday.new do |faraday|
          faraday.request :url_encoded
          faraday.headers = headers
          faraday.use RequestLogger if debug
        end
        response = client.post(
          "https://account.xiaomi.com/pass/serviceLoginAuth2",
          data
        )
        JSON.parse(response.body.sub("&&&START&&&", ""))
      end

      def security_token_service(sid, location, nonce, ssecurity)
        cookies = DEFAULT_COOKIES
        headers = DEFAULT_HEADERS.merge({
                                          "Cookie" => Mi::Utils.cookie2str(cookies)
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
        if service_token
          @info[sid] = [ssecurity, service_token]
          @success = true
        end
        response
      end

      def mi_request; end

      def auth_cookies(sid)
        return {} if @info[sid].nil?

        {
          "userId" => @info["userId"],
          "serviceToken" => @info[sid][1]
        }
      end

      def success?
        @success
      end

      def authed_by_sid?(sid)
        !@info[sid].nil?
      end

      private

      def md5_hash(string)
        Digest::MD5.hexdigest(string).upcase
      end
    end
  end
end
