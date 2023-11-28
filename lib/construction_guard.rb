# frozen_string_literal: true

require_relative "construction_guard/version"
require "construction_guard/middleware"
require "construction_guard/configuration"
require 'construction_guard/renderer'
require "logger"
require "dotenv/load"

module ConstructionGuard
  class Error < StandardError; end
  # Your code goes here...

  # Add a logger instance
  LOGGER = Logger.new(STDOUT)

end
