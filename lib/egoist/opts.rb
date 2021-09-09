class Policy
  OPTS = {
    fallback_policy: nil,
    current_user: nil
  }

  class << self
    def get name
      is_valid_option? name
      value = OPTS[name]
      value.is_a?(Proc) ? value.call : value
    end

    def set name, value=nil, &block
      is_valid_option? name
      OPTS[name] = block || value
    end

    def is_valid_option? name
      unless OPTS.key?(name)
        raise NameError.new('Policy option "%s" not found, defined: %s' % [name, OPTS.keys.join(', ')])
      end
    end
  end
end

###

Policy.set :fallback_policy, 'ModelPolicy'

Policy.set :current_user do
  if defined?(User) && User.respond_to?(:current)
    User.current
  elsif defined?(Current) && Current.respond_to?(:user)
    Current.user
  else
    raise RuntimeError.new('Current user not found in Policy#current_user')
  end
end

