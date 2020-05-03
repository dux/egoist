class Policy
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
        yield
        return nil
      end

      if action == '!'
        raise error
      elsif action == '?'
        nil
      else
        raise ArgumentError.new('Bad policy method %s' % name)
      end
    end
  end
end