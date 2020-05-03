class Policy
  attr_reader :model, :user, :action

  def initialize model:, user:
    @model = model
    @user  = user || current_user
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

  def can
    Proxy.new self
  end

  private

  # call has to be isolated because specific of error handling
  def call *args, &block
    raise Error, 'User is not defined, no access' unless @user

    return true if before(@action)
    return true if send(@action, *args)

    raise Error, 'Access disabled in policy'
  rescue Policy::Error => error
    message = error.message
    message += " - #{self.class}##{@action}"

    if block
      block.call(message)
      false
    else
      raise Policy::Error, message
    end
  end

  def before action
    false
  end

  def error message
    raise Policy::Error.new(message)
  end

  # get current user from globals if globals defined
  def current_user
    if defined?(User) && User.respond_to?(:current)
      User.current
    elsif defined?(Current) && Current.respond_to?(:user)
      Current.user
    else
      raise RuntimeError.new('Current user not found in Policy#current_user')
    end
  end
end
