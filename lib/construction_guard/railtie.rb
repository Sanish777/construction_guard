# frozen_string_literal: true

require 'rails/railtie'

module ConstructionGuard
  class Railtie < Rails::Railtie
    initializer 'construction_guard.insert_middleware' do |app|
      app.middleware.use Middleware
    end
  end
end
