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

    it 'accepts model and action' do
      User.current = admin_user
      controller.authorize(post, :write?)
      expect(controller.is_authorized?).to be true
    end

    it 'is_authorized? is true' do
      User.current = admin_user
      controller.authorize :admin?
      expect(controller.is_authorized?).to be true
    end

    it 'is_authorized? is true for block' do
      controller.authorize(:admin?) { nil }
      expect(controller.is_authorized?).to be true
    end

    it 'accepts only true as an argument' do
      controller.authorize(true)
      expect(controller.is_authorized?).to be true
    end
  end
end