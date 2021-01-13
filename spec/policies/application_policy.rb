# policy without models

class ApplicationPolicy < Policy
  def before action
    return true if action == :before_1?
  end

  def after action
    error 'Not allowed' if action == :before_3?
    true
  end

  def admin?
    @user.is_admin
  end

  def before_1?
    raise 'abc'
  end

  def before_2?
    false
  end

  def before_3?
    true
  end

  def before_4?
    true
  end

  def custom_error?
    error 'foo'
  end
end