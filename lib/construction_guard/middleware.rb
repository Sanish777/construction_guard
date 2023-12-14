# frozen_string_literal: true

require "net/http"

module ConstructionGuard
  class Middleware
    attr_accessor :under_construction, :maintenance_message

    def initialize(app, options = {})
      @app = app
      @under_construction = options.fetch(:under_construction, true) # Set default to true (under construction)
      @maintenance_message = options.fetch(:maintenance_message,
                                           "This site is currently under maintenance. Please check back later.")
      @flash = ConstructionGuard::Configuration.new
    end

    def call(env)
      request = Rack::Request.new(env)

      if request.cookies["user_data"].blank? && request.cookies["unauthorized_session"]
        @flash.error("Failed to authenticate the user.")
      end

      if under_construction && request.get? && request.path != "/constructionguard/github/callback" && request.cookies["unlocked"].nil?
        # Show the "under construction" page if the user is not unlocked
        return [200, {"Content-Type" => "text/html"}, [under_construction_response(@flash.get(:error))]]
      end

      @app.call(env)
    end

    def self.setup_omniauth(_request = nil, response = nil, code = nil)
      return unless code

      token_data = ConstructionGuard::Middleware.exchange_code(code)

      if token_data.key?("access_token")
        token = token_data["access_token"]
        user_details = ConstructionGuard::GithubOauth.retrieve_user_details(token)

        is_member = ConstructionGuard::GithubOauth.retrieve_organization_membership(
          user_details["login"], token
        )

        user_info = user_info(token)
        name = user_info["name"]

        # 204 status code, if requester is an organization member and user is a member
        # 302 status code, if requester is not an organization member
        # 404 status code, Not Found if requester is an organization member and user is not a member
        if is_member.code.to_i == 204
          response.set_cookie("user_data", {value: name, expires: Time.now + (7 * 24 * 60 * 60), path: "/"})
          response.set_cookie("unlocked", {value: "true", expires: Time.now + (7 * 24 * 60 * 60), path: "/"})
        else
          response.set_cookie("unauthorized_session", {value: "true", expires: Time.now + 30, path: "/"})
        end
      else
        p "Authorized, but unable to exchange code #{code} for token."
      end
    end

    # exchange_code
    def self.exchange_code(code)
      params = {
        "client_id" => CLIENT_ID,
        "client_secret" => CLIENT_SECRET,
        "code" => code
      }

      p "HELLO FROM SETUP OMNIAUTH #{params}"
      result = Net::HTTP.post(
        URI("https://github.com/login/oauth/access_token"),
        URI.encode_www_form(params),
        {"Accept" => "application/json"}
      )

      ConstructionGuard::Middleware.parse_response(result)
    end

    # user_info
    def self.user_info(token)
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

      ConstructionGuard::Middleware.parse_response(result)
    end

    # parse_response
    def self.parse_response(response)
      case response
      when Net::HTTPOK
        JSON.parse(response.body)
      else
        puts response
        puts response.body
        {}
      end
    end

    private

    def under_construction_response(flash)
      # The HTML content for the "Under Construction" page.
      # You can customize this page as you like.
      ConstructionGuard::Renderer.render_template(:default_template, message: maintenance_message,
                                                                     login_message: flash)
    end
  end
end
