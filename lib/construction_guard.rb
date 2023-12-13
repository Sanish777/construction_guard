# frozen_string_literal: true

require_relative "construction_guard/version"
require "construction_guard/middleware"
require "construction_guard/configuration"
require "construction_guard/renderer"
require "construction_guard/github_oauth/github_oauth"
require "logger"
require "net/http"
require "json"
require "dotenv/load"
require "rest-client"

CLIENT_ID=ENV["CLIENT_ID"]
CLIENT_SECRET=ENV["CLIENT_SECRET"]
ORGANIZATION=ENV["ORGANIZATION_NAME"]

module ConstructionGuard
  class Error < StandardError; end
end
