# lib/construction_guard/middleware.rb

require "net/http"
CLIENT_ID = "abc"

module ConstructionGuard
  class Middleware
    attr_accessor :under_construction, :maintenance_message

    def initialize(app, options = {})
      @app = app
      @under_construction = options.fetch(:under_construction, true) # Set default to true (under construction)
      @maintenance_message = options.fetch(:maintenance_message,
                                           "This site is currently under maintenance. Please check back later.")
    end

    def call(env)
      request = Rack::Request.new(env)
      if under_construction? && (request.get? && request.path == "/") && request.cookies["unlocked"].nil?
        # Show the "under construction" page if the user is not unlocked
        return [200, {"Content-Type" => "text/html"}, [under_construction_response]]
      end

      @app.call(env)
    end

    class << self
      def setup_omniauth(_request = nil, response = nil, code = nil)
        return unless code

        token_data = exchange_code(code)

        if token_data.key?("access_token")
          token = token_data["access_token"]

          user_info = user_info(token)
          name = user_info["name"]

          response.set_cookie("user_data", {
                                value: name,
                                expires: Time.now + (7 * 24 * 60 * 60), # Set to expire after 1 week
                                path: "/" # Set the appropriate path
                              })
        else
          p "Authorized, but unable to exchange code #{code} for token."
        end
        response.set_cookie("unlocked", {
                              value: "true",
                              expires: Time.now + (7 * 24 * 60 * 60), # Set to expire after 1 week
                              path: "/" # Set the appropriate path
                            })
      end

      # exchange_code
      def exchange_code(code)
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
    end

    private

    def under_construction?
      under_construction
    end

    def under_construction_response
      # The HTML content for the "Under Construction" page.
      # You can customize this page as you like.
      ConstructionGuard::Renderer.render_template(:default_template, message: maintenance_message)
    end

    def emails
      # Access the configuration file from the Rails application
      config_file = Rails.root.join("config", "underconstruction_guard.yml")
      config_data = YAML.load_file(config_file) if File.exist?(config_file)

      # Retrieve the 'emails' key from the config data
      config_data["emails"] || []
    end

    def email_matched?(email_to_check)
      allowed_emails = emails
      allowed_emails.include?(email_to_check)
    end
  end
end
