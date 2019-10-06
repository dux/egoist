require 'spec_helper'

describe Policy do
  let!(:user)       { mock.create :user }
  let!(:admin_user) { mock.create :user, is_admin: true }

  before do
    User.current = nil
  end

  context 'without model' do
    it 'cant access admin pages' do
      # checks on ApplicationPolicy
      expect(Policy(user: user).admin?).to be_falsy
    end

    it 'can access admin pages' do
      # checks on ApplicationPolicy
      expect(Policy(user: admin_user).admin?).to be_truthy
    end

    it 'raises error on action not found' do
      # checks on ApplicationPolicy
      expect { Policy(user: user).not_defined? } .to raise_error NoMethodError
    end
  end

  context 'with model' do
    it 'cant write not owned object' do
      post = mock.create :post, created_by: user.id + 9

      # checks on PostPolicy
      expect(Policy(post, user: user).write?).to be_falsy
    end

    it 'can write owned object' do
      # checks on PostPolicy as regular user
      post = mock.create :post, created_by: user.id
      expect(Policy(post, user: user).write?).to be_truthy

      # checks on PostPolicy as admin
      post = mock.create :post, created_by: user.id + 9
      expect(Policy(post, user: admin_user).write?).to be_truthy
    end
  end

  context 'accessed via proxy' do
    it 'can write as admin' do
      # checks on PostPolicy via proxy object and magic user
      User.current = admin_user
      post = mock.create :post
      expect(post.can.write?).to be_truthy
    end

    it 'cant write as user' do
      # checks on PostPolicy via proxy object
      User.current = user
      post = mock.create :post
      expect(post.can.write?).to be_falsy
    end
  end
end