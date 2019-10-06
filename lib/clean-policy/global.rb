def Policy *args
  opts = args.first.dup

  unless opts.is_a?(Hash)
    opts = { model: opts }
    opts.merge! args[1] if args[1]
  end

  raise ArgumentError, 'User not defined' unless opts.key?(:user)

  model = opts[:model]

  klass =
  if model
    opts[:class] || ('%s_policy' % model.class).classify.constantize
  else
    ApplicationPolicy
  end

  klass.new(user: opts[:user], model: model)
end

# "smart" access that will fill current user if possible
# fell free to overwrite this method
class Object
  def policy *args
    opts = args.first.dup

    unless opts.is_a?(Hash)
      opts = { model: opts }
      opts.merge! args[1] if args[1]
    end

    opts[:user] ||= user_current if respond_to?(:user_current)
    opts[:user] ||= User.current if defined?(User) && User.respond_to?(:current)

    Policy opts
  end
end