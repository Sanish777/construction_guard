# frozen_string_literal: true

module ConstructionGuard::Middleware
  def initialize(app)
    @app = app
  end

  def call(env)
    return [200, { 'Content-Type' => 'text/html' }, [under_construction_response]] if under_construction?

    @app.call(env)
  end

  def connection
    "-------------Connection Established-------------"
  end

  private

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
    <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <title>Under Construction</title>
        </head>
        <body>
          <h1>Under Construction</h1>
          <p>This website is currently under construction. Please check back later.</p>
        </body>
      </html>
    HTML
  end
end
