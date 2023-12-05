# frozen_string_literal: true

require "sinatra"
require "dotenv/load"
require "net/http"
require "json"

CLIENT_ID = "abc"
CLIENT_SECRET = "abc"

# lib/construction_guard/github_omni_auth.rb
module ConstructionGuard
  class GithubOmniAuth
    class << self
      attr_accessor :logger
    end

    self.logger = Logger.new(STDOUT)

    class << self
      # parse_response
      def parse_response
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
        result = Net::HTTP.post(
          URI("https://github.com/login/oauth/access_token"),
          URI.encode_www_form(params),
          {"Accept" => "application/json"}
        )

        parse_response(result)
      end

      # user_info
      def user_info(token)
        uri = URI("https://github.com/api/v3/user")

        result = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          body = {"access_token" => token}.to_json

          auth = "Bearer #{token}"
          headers = {"Accept" => "application/json", "Content-Type" => "application/json", "Authorization" => auth}

          http.send_request("GET", uri.path, body, headers)
        end

        parse_response(result)
      end

      get "/" do
        link = '<a href="https://github.com/login/oauth/authorize?client_id=<%= CLIENT_ID %>">Login with GitHub</a>'
        erb link
      end

      get "/construction/github/callback" do
        code = params["code"]

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
    end
  end
end
