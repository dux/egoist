class Policy
  module ModelAdapter
    def self.can user, model
      klass = '%sPolicy' % model.class
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
