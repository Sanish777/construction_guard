module ConstructionGuard
  class Configuration
    def initialize
      @messages = {}
    end

    def set(key, value)
      @messages[key] = value
    end

    def success(message)
      set(:success, message)
    end

    def error(message)
      set(:error, message)
    end

    def get(key)
      @messages[key]
      @messages.delete(key)
    end
  end
end
