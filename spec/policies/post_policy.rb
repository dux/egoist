class PostPolicy < Policy
  def write?
    @user.is_admin || @user.id == @model.created_by
  end
end