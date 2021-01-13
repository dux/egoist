class Policy
  class Error < StandardError
  end
end

class Policy
  class << self
    def error msg
      raise ::Policy::Error.new(msg)
    end
  end

  ###

  def error message
    raise Policy::Error.new(message)
  end
end

