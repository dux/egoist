class Policy
  module ModelAdapter
    extend self

    def can user=nil, model=nil
      klass = "#{self.class}Policy"
      klass = Object.const_defined?(klass) ? klass.constantize : ModelPolicy
      Policy(model: model || self, user: user, class: klass)
    end
  end
end

if defined? Rails
  ActiveModel::Base.include Policy::ModelAdapter
elsif defined? Sequel
  class Sequel::Model
    module InstanceMethods
      def can user=nil
        Policy::ModelAdapter.can user, self
      end
    end
  end
end
