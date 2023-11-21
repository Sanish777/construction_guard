# lib/construction_guard/middleware.rb

require "google/apis/groupssettings_v1"
require "googleauth"
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

        if under_construction? && email_matched?(email, fetch_allowed_emails)
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

    def fetch_allowed_emails
      # Use the Google Groups API to fetch allowed emails
      group_email = "your-group@example.com" # Replace with your actual group email
      group_settings = Google::Apis::GroupssettingsV1::GroupssettingsService.new
      group_settings.authorization = authorizer # Make sure to set up authorization as in the previous examples

      begin
        group_settings.get_groups_settings(group_email).who_can_post_message_moderation
      rescue StandardError => e
        # Handle API errors or log them
        puts "Error fetching allowed emails: #{e.message}"
        []
      end
    end

    def email_matched?(email_to_check, allowed_emails)
      allowed_emails.include?(email_to_check)
    end

    def authorizer
      # Create an OAuth2 service account authorizer from the environment variables
      Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(ENV["GOOGLE_API_CREDENTIALS_JSON"]),
        scope: Google::Apis::GroupssettingsV1::AUTH_APPS_GROUPS_SETTINGS
      )
    end
  end
end
