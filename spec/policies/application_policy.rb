class ApplicationPolicy < Policy
  def admin?
    @user.is_admin
  end
end