for lib in %w(base error proxy global framework_adapter)
  require_relative './clean-policy/%s' % lib
end