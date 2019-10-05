version  = File.read File.expand_path '.version', File.dirname(__FILE__)
gem_name = 'clean-policy'

Gem::Specification.new gem_name, version do |gem|
  gem.summary     = 'Ruby access policy library'
  gem.description = 'Clean, simple explicit and strait-forward policy definitions.'
  gem.authors     = ["Dino Reic"]
  gem.email       = 'reic.dino@gmail.com'
  gem.files       = Dir['./lib/**/*.rb']+['./.version']
  gem.homepage    = 'https://github.com/dux/%s' % gem_name
  gem.license     = 'MIT'
end