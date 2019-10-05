require 'spec_helper'

describe Policy do
  let!(:user) { mock.create :user }

  context 'without model' do
    it 'cant access admin pages' do
      expect(Policy(user: user).admin?).to be_falsy
    end

    it 'can access admin pages' do
      user = mock.create :user, is_admin: true
      expect(Policy(user: user).admin?).to be_truthy
    end

    it 'raises error on action not found' do
      expect { Policy(user: user).not_defined? } .to raise_error NoMethodError
    end
  end

  context 'with model' do
    it 'cant write not owned object' do
      post = mock.create :post, created_by: user.id + 9

      expect(Policy(post, user: user).write?).to be_falsy
    end

    it 'can write owned object' do
      # as regular user
      post = mock.create :post, created_by: user.id
      expect(Policy(post, user: user).write?).to be_truthy

      # as admin
      user = mock.create :user, is_admin: true
      post = mock.create :post, created_by: user.id + 9
      expect(Policy(post, user: user).write?).to be_truthy
    end
  end
end