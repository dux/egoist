class Policy
  class << self
    # convenient proxy access
    def can model=nil, user=nil
      if model.is_a?(Hash)
        model, user = model[:model], model[:user]
      end

      klass = self

      # if we are calling can on Policy class, figure out policy class or fall back to fallback_policy
      if self == Policy
        klass = ('%s_policy' % model.class).classify
        klass = Object.const_defined?('::%s' % klass) ? klass.constantize : ::ModelPolicy
      end

      klass.new(user: user, model: model).can
    end
  end

  ###

  class Proxy
    def initialize policy
      @policy = policy
    end

    def method_missing name, *args, &block
      name   = name.to_s.sub(/(.)$/, '')
      action = $1

      @policy.can?(name, *args)
      @policy.model || true
    rescue Policy::Error => error
      if block_given?
        yield error
        nil
      elsif action == '!'
        raise error
      elsif action == '?'
        nil
      else
        raise ArgumentError.new('Bad policy method %s' % name)
      end
    end
  end
end
