class Policy
  class << self
    def error msg
      raise ::Policy::Error.new(msg)
    end
  end

  ###

  class Error < StandardError
  end
end
