module ConstructionGuard
  class Configuration
    attr_accessor :under_construction, :maintenance_message

    def initialize
      @under_construction = options.fetch(:under_construction, false)
      @maintenance_message = options.fetch(:maintenance_message,
                                           "This site is currently under maintenance. Please check back later.")
    end
  end
end
