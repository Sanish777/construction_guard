# lib/construction_guard/middleware.rb
module ConstructionGuard
  class Middleware
    attr_accessor :under_construction, :maintenance_message

    def initialize(app, options = {})
      @app = app

      @under_construction = options.fetch(:under_construction, false)
      @maintenance_message = options.fetch(:maintenance_message, "This site is currently under maintenance. Please check back later.")
    end

    def call(env)
      return [200, { 'Content-Type' => 'text/html' }, [under_construction_response]] if under_construction?

      @app.call(env)
    end

    def under_construction?
      # Implement your logic here to check if the application is under construction
      # For simplicity, you can use an environment variable or a configuration setting
      # to toggle the under construction state.
      # Example:
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
          </body>
        </html>
      HTML
    end
  end
end
