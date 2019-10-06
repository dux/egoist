class PostPolicy < Policy
  def write?
    @user.is_admin || @user.id == @model.created_by
  end

  def create? opts={}
    opts[:ip] == '1.2.3.4'
  end
end