require 'spec_helper'

module Lux
  class Controller
    include Policy::Controller
  end
end

class Mocvara
  include Policy::Model
end

class MocvaraPolicy < Policy
  def admin?
    user.is_admin
  end
end


describe Policy do
  let(:controller)  { Lux::Controller.new }
  let!(:post)       { mock.create :post }
  let!(:admin_user) { mock.create :user, is_admin: true }

  before do
    User.current = nil
  end

  context 'authorize checks if' do
    it 'is_authorized? is false' do
      expect(controller.is_authorized?).to be false
    end

    it 'accepts block as an argument' do
      User.current = admin_user
      controller.authorize { true }
      expect(controller.is_authorized?).to be true
    end

    it 'accepts only true as an argument' do
      controller.authorize(true)
      expect(controller.is_authorized?).to be true
    end

    it 'fails on is_authorized! bang check' do
      expect { controller.is_authorized! }.to raise_error Policy::Error
    end

    it 'fails on false pass' do
      expect { controller.authorize(false) }.to raise_error Policy::Error
    end
  end

  context 'model checks' do
    let(:user) { User.new 1, 'Dux', 'dux@foo.bar', true }

    it 'checks if it can work trough model' do
      expect(Mocvara.new.can(user).admin?).to eq(true)
    end

    it 'checks if it can access current user' do
      User.current = user
      expect(Mocvara.new.can.admin?).to eq(true)
    end
  end
end