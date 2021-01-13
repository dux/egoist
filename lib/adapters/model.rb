klass =
if defined? ActiveRecord
  ActiveRecord::Base
elsif defined? Sequel
  Sequel::Model
end

if klass
  klass.class_eval do
    def can user=nil
      puts 12345
      Policy.can self, user
    end
  end
end
