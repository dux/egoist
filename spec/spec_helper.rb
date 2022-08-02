require 'amazing_print'
require 'clean-mock'
require 'faker'
require 'dry/inflector'

class String
  def classify;     Dry::Inflector.new.classify self; end
  def constantize;  Dry::Inflector.new.constantize self; end
  def singularize;  Dry::Inflector.new.singularize self; end
end

require_relative '../lib/egoist'

require_relative './mocks/users'
require_relative './mocks/posts'

require_relative './policies/application_policy'
require_relative './policies/post_policy'
require_relative './policies/headless_policy'

class Object
  def rr data
    puts '- start: %s' % data.inspect
    ap data
    puts '- end'
  end
end

# basic config
RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true

  # # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :json, CustomFormatterClass
end


