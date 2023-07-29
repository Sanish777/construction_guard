# lib/construction_guard/middleware.rb
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

      if request.get? && under_construction? && request.params["unlock"] == "secret_password"
        @under_construction = false # Disable under construction if the correct unlock password is provided
        return [302, {"Location" => request.url}, []] # Redirect to the same page after unlocking
      end

      return [200, {"Content-Type" => "text/html"}, [under_construction_response]] if under_construction?

      @app.call(env)
    end

    def under_construction?
      under_construction
    end

    def under_construction_response
      # The HTML content for the "Under Construction" page.
      # You can customize this page as you like.
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>Under Construction</title>
          </head>
          <body>
            <h1>Under Construction</h1>
            <p>#{maintenance_message}</p>
            <form action="/" method="GET"> <!-- Replace "/" with the correct URL to unlock the site -->
              <input type="text" name="unlock" placeholder="Enter unlock password">
              <button type="submit">Unlock</button>
            </form>
          </body>
        </html>
      HTML
    end
  end
end
