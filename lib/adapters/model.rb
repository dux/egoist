klass =
if defined? ActiveRecord
  ActiveRecord::Base
elsif defined? Sequel
  Sequel::Model
end

if klass
  klass.class_eval do
    def can user=nil
      Policy.can self, user
    end
  end
end
