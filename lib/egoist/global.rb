# Policy(:application)              -> ApplicationPolicy.can(model: nil, user: current_user)
# Policy(@post)                     -> PostPolict.can(model: @post, user: current_user)
# Policy(@post, @user)              -> PostPolict.can(model: @post, user: @user)
# Policy(model: @post, user: @user) -> PostPolict.can(model: @post, user: @user)
def Policy model, user=nil
  if model.is_a?(Hash)
    user, model = model[:user], model[:model]
  end

  raise ArgumentError, 'Model not defined' unless model

  klass = model.is_a?(Symbol) ? model : model.class
  klass = ('%s_policy' % klass).classify.constantize

  klass.new(user: user, model: model).can
end
