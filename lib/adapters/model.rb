# include Policy::Model

class Policy
  module Model
    def can user = nil
      Policy.can model: self, user: user
    end
  end
end
