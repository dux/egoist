klass =
if defined? Rails
  ActionController::Base
elsif defined? Lux
  Lux::Controller
end

if klass
  klass.class_eval do
    def authorize *args, &block
      opts = {}

      @_is_policy_authorized = true

      raise ArgumentErorr, 'authorize argument[s] not provided' unless args[0]

      # authorize true
      return if args[0].is_a? TrueClass

      if !args[1]
        # authorize :admin?
        opts[:action] = args.first
      elsif args[2]
        # authorize @model, write?, CustomClass
        # authorize @model, write?, class: CustomClass
        opts[:model]  = args.first
        opts[:action] = args[1]
        opts[:class]  = args[2].is_a?(Hash) ? args[2][:class] : args[2]
      else
        # authorize @model, write?
        opts[:model]  = args.first
        opts[:action] = args[1]
      end

      # covert all authorize actions to bang actions (fail unless true)
      action = opts.delete(:action).to_s.sub('?', '!')

      # do it
      Policy(opts).send(action, &block)
    end

    def is_authorized?
      !!@_is_policy_authorized
    end
  end
end
