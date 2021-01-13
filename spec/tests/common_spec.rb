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
      expect { ApplicationPolicy.can(user).admin! }.to raise_error Policy::Error
    end

    it 'can access admin pages' do
      # checks on ApplicationPolicy
      expect(ApplicationPolicy.can(user: admin_user).admin?).to be_truthy
    end

    it 'raises error on action not found' do
      # checks on ApplicationPolicy
      expect { ApplicationPolicy.can(user: user).not_defined? } .to raise_error NoMethodError
    end

    it 'processes before filter' do
      expect{ ApplicationPolicy.can(user: user).before_2! }.to raise_error Policy::Error
    end

    it 'accepts error block in bang method' do
      test = false
      ApplicationPolicy.can(user: user).admin! { test = true }
      expect(test).to be_truthy
    end

    it 'accepts error block in question method' do
      test = false
      ApplicationPolicy.can(user).admin? { test = true }
      expect(test).to be_truthy
    end

    it 'accepts symbol as a model' do
      test = HeadlessPolicy.can(user: user).read?
      expect(test).to be_truthy
    end

    it 'checks using user in Thread current' do
      expect(ApplicationPolicy.can.admin?).to be_nil

      User.current = user
      expect(ApplicationPolicy.can.admin?).to be_nil

      User.current = admin_user
      expect(ApplicationPolicy.can.admin?).to be_truthy
    end
  end

  context 'with model' do
    it 'cant write not owned object' do
      post = mock.create :post, created_by: user.id + 9

      # checks on PostPolicy
      expect(PostPolicy.can(model: post, user: user).write?).to be_falsy
    end

    it 'can write owned object' do
      # checks on PostPolicy as regular user
      post = mock.create :post, created_by: user.id
      expect(PostPolicy.can(post, user).write?).to be_truthy

      # checks on PostPolicy as admin
      post = mock.create :post, created_by: user.id + 9
      expect(PostPolicy.can(user: admin_user).write?).to be_truthy
    end

    it 'accepts a function parameter' do
      expect( PostPolicy.can(post, user).create?({ip: '1.2.3.4'}) ).to be_truthy
      expect { PostPolicy.can(post, user).create!({ip: '2.3.4.5'}) }.to raise_error Policy::Error
    end

    it 'is accessible via can and accepts attributes' do
      expect(PostPolicy.can(user, post).create?({ip: '1.2.3.4'})).to be_truthy
    end

    it 'follows rules in after block' do
      expect { ApplicationPolicy.can(user: user).before_3! }.to raise_error Policy::Error
      expect(ApplicationPolicy.can(user: user).before_4!).to be_truthy
    end
  end
end