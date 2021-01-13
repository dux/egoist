klass =
if defined? Rails
  ActionController::Base
elsif defined? Lux
  Lux::Controller
end

if klass
  klass.class_eval do
    def authorize result=false
      if (block_given? ? yield : result)
        @_is_policy_authorized = true
      else
        Policy.error('Authorize did not pass truthy value')
      end
    end

    def is_authorized?
      @_is_policy_authorized == true
    end

    def is_authorized!
      if is_authorized?
        true
      else
        Policy.error('Request is not authorized!')
      end
    end
  end
end
