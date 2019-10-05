User = Struct.new :id, :name, :email, :is_admin

mock :user do |user, opts|
  user.id       = sequence :user_id
  user.name     = opts[:name]     || Faker::Name.name
  user.email    = opts[:email]    || Faker::Internet.email
  user.is_admin = opts[:is_admin] || false
end