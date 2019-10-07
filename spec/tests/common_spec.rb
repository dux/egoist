require 'spec_helper'

describe Policy do
  let!(:post)       { mock.create :post }
  let!(:user)       { mock.create :user }
  let!(:admin_user) { mock.create :user, is_admin: true }

  before do
    User.current = nil
  end

  context 'without model' do
    it 'cant access admin pages' do
      # checks on ApplicationPolicy
      expect { Policy(user: user).admin! }.to raise_error Policy::Error
    end

    it 'can access admin pages' do
      # checks on ApplicationPolicy
      expect(Policy(user: admin_user).admin?).to be_truthy
    end

    it 'raises error on action not found' do
      # checks on ApplicationPolicy
      expect { Policy(user: user).not_defined? } .to raise_error NoMethodError
    end

    it 'processes before filter' do
      expect(Policy(user: user).before_1?).to be_truthy
      expect{ Policy(user: user).before_2! }.to raise_error Policy::Error
    end

    it 'accepts error block in bang method' do
      test = false
      Policy(user: user).admin! { test = true }
      expect(test).to be_truthy
    end

    it 'accepts error block in question method' do
      test = false
      Policy(user: user).admin? { test = true }
      expect(test).to be_truthy
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

    it 'accepts a function parameter' do
      expect( Policy(post, user: user).create?({ip: '1.2.3.4'}) ).to be_truthy
      expect { Policy(post, user: user).create!({ip: '2.3.4.5'}) }.to raise_error Policy::Error
    end

    it 'is accessible via can and accepts attributes' do
      expect(Policy(post, user: user).create?({ip: '1.2.3.4'})).to be_truthy
    end
  end

  context 'accessed via proxy' do
    it 'raise custom error' do
      expect { Policy(user: user).custom_error! }.to raise_error Policy::Error
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