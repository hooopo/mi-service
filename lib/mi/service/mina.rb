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
    class Mina
      attr_reader :account, :debug

      DEFAULT_HEADERS = {
        "User-Agent": "MiHome/6.0.103 (com.xiaomi.mihome; build:6.0.103.1; iOS 14.4.0) Alamofire/6.0.103 MICO/iOSApp/appStore/6.0.103"
      }.freeze

      def initialize(account, debug: false)
        @debug = debug
        @account = account
      end

      def device_list(master = 0)
        sid = "micoapi"
        url = "https://api2.mina.mi.com/admin/v2/device_list?master=#{master}"
        request_id = "app_ios_#{Mi::Utils.get_random(30)}"
        url += "&requestId=#{request_id}"

        client = Faraday.new(url) do |f|
          f.response :logger if debug
          f.headers = DEFAULT_HEADERS.merge("Cookie" => Mi::Utils.cookie2str(account.auth_cookies(sid)))
        end

        response = client.get(url)
        JSON.parse(response.body)["data"]
      end

      def text_to_speech(device_id, text)
        sid = "micoapi"
        url = "https://api2.mina.mi.com/remote/ubus"
        request_id = "app_ios_#{Mi::Utils.get_random(30)}"
        data = {
          "requestId" => request_id,
          "deviceId" => device_id,
          "method" => "text_to_speech",
          "path" => "mibrain",
          "message" => { text: text }.to_json
        }

        client = Faraday.new(url) do |f|
          f.response :logger if debug
          f.request :url_encoded
          f.headers = DEFAULT_HEADERS.merge("Cookie" => Mi::Utils.cookie2str(account.auth_cookies(sid)))
        end
        response = client.post(url, data)
        JSON.parse(response.body)
      end
    end
  end
end
