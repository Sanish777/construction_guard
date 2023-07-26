# frozen_string_literal: true

module ConstructionGuard
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      if under_construction?
        render_under_construction_page
      else
        @app.call(env)
      end
    end

    private

    def under_construction?
      # Implement your logic here to check if the application is under construction
      # For simplicity, you can use an environment variable or a configuration setting
      # to toggle the under construction state.
      # Example:
      ENV['SITE_ARMOR_UNDER_CONSTRUCTION'] == 'true'
    end

    def render_under_construction_page
      # Return a static under construction page.
      # You can create an HTML file or use an ERB template to render the page.
      # For simplicity, we'll return a simple response here.
      [200, { 'Content-Type' => 'text/html' }, ['<html><body>Under Construction!</body></html>']]
    end
  end
end
