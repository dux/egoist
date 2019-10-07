class Policy
  class Proxy
    def initialize policy
      @policy = policy
    end

    def method_missing name, &block
      name   = name.to_s.sub(/(.)$/, '')
      action = $1

      if action == '!'
        @policy.can?(name, &block)
        true
      elsif action == '?'
        raise "Block given, not allowed in boolean (?) policy, use bang .#{name}! { .. }" if block_given?

        begin
          @policy.can?(name)
          true
        rescue Policy::Error
          yield if block_given?
          false
        end
      else
        raise ArgumentError.new('Bad policy method name')
      end
    end
  end
end