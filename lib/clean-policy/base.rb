class Policy
  attr_reader :model, :user, :action

  def initialize model:, user:
    @model = model
    @user  = user
  end

  # pass block if you want to handle errors yourself
  # return true if false if block is passed
  def can? action, *args, &block
    @action = action
      .to_s
      .gsub(/[^\w+]/, '')
      .concat('?')
      .to_sym

    # pre check
    raise RuntimeError, 'Method name not allowed' if %i(can).index(@action)
    raise NoMethodError, %[Policy check "#{@action}" not found in #{self.class}] unless respond_to?(@action)

    call *args, &block
  end

  # call has to be isolated because specific of error handling
  def call *args, &block
    raise Error.new 'User is not defined' unless @user

    return true if before(@action)
    return true if send(@action, *args)
    raise Error.new('Access disabled in policy')
  rescue Policy::Error => e
    error = e.message
    error += " - #{self.class}.#{@action}" if defined?(Lux) && Lux.config(:dump_errors)

    if block
      block.call(error)
      false
    else
      raise Policy::Error, error
    end
  end

  def can
    Proxy.new self
  end

  ###

  def before action
    false
  end

  def error message
    raise Policy::Error.new(message)
  end

end
