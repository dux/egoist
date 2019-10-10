# accepts: user:, model:, class:
# accepts: @model, class:, user:
def Policy *args
  opts = args.first.dup

  unless opts.is_a?(Hash)
    opts = { model: opts }
    opts.merge! args[1] if args[1]
  end

  model = opts[:model]

  klass =
  if model
    klass = model.is_a?(Symbol) ? model : model.class
    opts[:class] || ('%s_policy' % klass).classify.constantize
  else
    ApplicationPolicy
  end

  klass.new(user: opts[:user], model: model).can
end
