# frozen_string_literal: true

require_relative "construction_guard/version"
require "construction_guard/middleware"
require "construction_guard/configuration"
require "construction_guard/renderer"
require "logger"
require "net/http"
require "json"

CLIENT_ID="abc"
CLIENT_SECRET="abc"

module ConstructionGuard
  class << self
    attr_accessor :logger
  end

  self.logger = Logger.new(STDOUT)

  class Error < StandardError; end
  # Your code goes here...

  class << self
    def setup_omniauth(code, response)
      token_data = exchange_code(code)

      if token_data.key?("access_token")
        token = token_data["access_token"]

        user_info = user_info(token)
        handle = user_info["login"]
        name = user_info["name"]

        logger.info "Successfully authorized! Welcome, #{name} (#{handle})."
      else
        logger.info "Authorized, but unable to exchange code #{code} for token."
      end
    end

    # parse_response
    def parse_response(response)
      case response
      when Net::HTTPOK
        JSON.parse(response.body)
      else
        puts response
        puts response.body
        {}
      end
    end

    # exchange_code
    def exchange_code(code)
      params = {
        "client_id" => CLIENT_ID,
        "client_secret" => CLIENT_SECRET,
        "code" => code
      }

      logger.info "HELLO FROM SETUP OMNIAUTH #{params}"
      result = Net::HTTP.post(
        URI("https://github.com/login/oauth/access_token"),
        URI.encode_www_form(params),
        {"Accept" => "application/json"}
      )

      parse_response(result)
    end

    # user_info
    def user_info(token)

      uri = URI.parse("https://api.github.com/user")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      auth = "Bearer #{token}"
      headers = {
        "Accept" => "application/json",
        "Authorization" => auth,
        "X-GitHub-Api-Version" => "2022-11-28"
      }

      request = Net::HTTP::Get.new(uri.request_uri, headers)
      result = http.request(request)

      parse_response(result)
    end
  end
end
