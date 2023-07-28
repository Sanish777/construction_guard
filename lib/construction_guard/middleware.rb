# lib/construction_guard/middleware.rb
require "erb"
module ConstructionGuard
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      return [200, {"Content-Type" => "text/html"}, [under_construction_response]] if under_construction?

      @app.call(env)
    end

    def under_construction?
      # Implement your logic here to check if the application is under construction
      # For simplicity, you can use an environment variable or a configuration setting
      # to toggle the under construction state.
      # Example:
      true
    end

    def under_construction_response
      # The HTML content for the "Under Construction" page.
      # You can customize this page as you like.
      html_content = <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <title>Under Construction</title>
          <link rel="stylesheet" href="/assets/construction_guard.css">
        </head>
        <body>
          <h1>Under Construction</h1>
          <p>This website is currently under construction. Please check back later.</p>

          <div class="form-container">
            <form action="/construction_guard/login" method="post">
              <div class="form-group">
                <label for="email">Email:</label>
                <input type="email" name="email" id="email" class="form-control">
              </div>
              <div class="form-group">
                <label for="password">Password:</label>
                <input type="password" name="password" id="password" class="form-control">
              </div>
              <button type="submit" class="btn btn-primary">Log In</button>
            </form>
          </div>
        </body>
      </html>
      HTML

      # Render the ERB template
      renderer = ERB.new(html_content)
      renderer.result(binding)
    end
  end
end
