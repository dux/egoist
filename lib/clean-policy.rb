for lib in %w(base error proxy global adapters/controller adapters/model)
  require_relative './clean-policy/%s' % lib
end