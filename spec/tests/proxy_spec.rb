require 'spec_helper'

describe Policy do
  let!(:post)       { mock.create :post }
  let!(:user)       { mock.create :user }
  let!(:admin_user) { mock.create :user, is_admin: true }

  before do
    User.current = nil
  end

  context 'accessed via proxy' do
    it 'raise custom error' do
      expect { ApplicationPolicy.can(user).custom_error! }.to raise_error Policy::Error
    end

    it 'can write as admin' do
      # checks on PostPolicy via proxy object and magic user
      User.current = admin_user
      expect(post.can.write?).to be_truthy
    end

    it 'cant write as user' do
      # checks on PostPolicy via proxy object
      User.current = user
      expect(post.can.write?).to be_falsy
    end

    it 'does not brake on truthy bang method' do
      User.current = admin_user
      expect(post.can.write!).to be_truthy
    end

    it 'raises error on bang method' do
      User.current = user
      expect { post.can.write! }.to raise_error Policy::Error
    end
  end
end