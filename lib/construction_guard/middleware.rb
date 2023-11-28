# lib/construction_guard/middleware.rb
require_relative "github_authentication/github_app_auth"

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


      # Check if the user is already unlocked (cookie set)
      if request.cookies["unlocked"] == "true"
        # The user is already unlocked, proceed with the request
        return @app.call(env)
      end

      if request.post? && request.path == "/unlock"
        # Handle the unlock form submission via POST
        unlock_password = request.params["unlock_password"]
        email = request.params["email"]

        if under_construction? && email_matched?(email) && unlock_password == ENV["CONSTRUCTION_PASSWORD"]
          # Set a cookie to indicate the user is unlocked
          response = Rack::Response.new
          response.set_cookie("unlocked", value: "true", expires: Time.now + (7 * 24 * 60 * 60)) # Set to expire after 1 week
          response.redirect("/") # Redirect to the homepage or any other page you desire
          return response.finish

        else
          # Show an error message or redirect to an error page if unlock is unsuccessful
          # ...
        end
      end

      if request.get? && request.path == "/github_login"
        access_token = GithubAuthentication::GithubAppAuth.login
        user_details = GithubAuthentication::GithubAppAuth.retrieve_user_details(access_token)
        is_member = GithubAuthentication::GithubAppAuth.retrieve_organization_membership(user_details["login"],
                                                                                         access_token)
        # 204 status code, if requester is an organization member and user is a member
        # 302 status code, if requester is not an organization member
        # 404 status code, Not Found if requester is an organization member and user is not a member
        if is_member.code.to_i == 204
          # Set a cookie to indicate the user is unlocked
          response = Rack::Response.new
          response.set_cookie("unlocked",
                              value: "true",
                              expires: Time.now + (7 * 24 * 60 * 60)) # Set to expire after 1 week
          response.redirect("/") # Redirect to the homepage or any other page you desire
          return response.finish
        end
      end

      if under_construction?
        # Show the "under construction" page if the user is not unlocked
        return [200, {"Content-Type" => "text/html"}, [under_construction_response]]
      end

      # Proceed with the request if the "under construction" mode is not active
      @app.call(env)
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
