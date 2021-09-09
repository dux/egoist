<img src="https://i.imgur.com/ssR9vHa.png" align="right" />

# Egoist - ruby access policy library

Egoist is ORM and framework agnostic, Ruby Access Policy library.

## Installation

to install

`gem install egoist`

or in Gemfile

`gem 'egoist'`

and to use

`require 'egoist'`

## How to use

Common usage is to use it directly on the model

```ruby
@commpany.can.read?  # true or false
@commpany.can.read!  # raise Policy::Error if false, or return true
```

If you want to contruct the object, usage is to load policy object and then execute the test

```ruby
# direct
@policy = BlogPolicy.can(user: current_user, model: @blog)
# or short
@policy = BlogPolicy.can(@blog, current_user)

# or if you do not use model
ApplicationPolicy.can(user: @user).access?

# call BlogPolicy (if available) or ModelPolicy if you use base Policy class
@policy = Policy.can(model: @blog, user: current_user)
# or short
@policy = Policy.can(@blog, current_user)

# or if you have User.current or Current.user or Current.user or Thread.current[:current_user] defined
# you do not have to pass the user
@policy = Policy.can(@blog)
@policy = BlogPolicy.can(@blog)
```

* `@policy.read?`

  this will return `truthy` value (`@model` or `true`) or `nil`.

*  `@policy.read!`

   If you bang! method instead of question mark, Policy will raise error instead of returning `nil`.

* `@policy.read? { redirect_to '/' }`

  If you provide a `&block`, `&block` will be executed first and then `nil` will be retuned.


That is all you need to know for calling policies.

## Main difference to popular lib - Pundit

* exposes friendly can method for models `@model.can.update?`
  * you can use question mark to return boolean `@model.can.update?` (`true`, `false`)
  * you can use bang! `@model.can.update!`, which will raise `Policy::Error` error on `false`
* you can pass block to policy check which will be evaluated on `false` policy check `@model.can.read? { redirect_to '/' }`
* exposes global `Policy` method, for easier access from where ever you need it `Policy.can(model: @model, user: @user).read?` (uses User.current or Current.user, can be customized)
* In `Policy` classes allows before filter to be defined. If it returns true, policy is not checked
  ```ruby
    def before action
      # if true, will not check the policy
      unless action == :delete?
        return true if user.is_admin?
      end
    end
  ```

* In `Policy` classes allows after filter to be defined. If it fails or returns false, policy check will fail. This is last line of defence in policy check.
  ```ruby
    def after action
      # if false or error, policy check will fail in the end
      if action == :delete?
        model.delete?

        if msg = model.errors.join(', ')
          error msg
        end
      end

      true
    end
  ```
* allows current user to be defined. Instead of `@model.can(current_user).update?` becomes "cleaner" `@model.can.update?`
* named error messages

## Controllrers and authorizations

Authorization check after the request is done, is basicly a rutime policy check. Use it in dashboards.

* you can pass only model, user, optional class and ability to test. It allways follows the same pattern: Can "this" user perform "this" action on "this" model? - clean!

* `auhthorize(@model, :read?)` or `auhthorize(@model, :read?)` will authorize model action and raise `Policy::Error` unlless one available.
* `is_authorized?` will return `true` or `false`.
* `is_authorized!` will raise `Policy::Error` unless authorized.

```ruby
class PostsController
  rescue_from Policy::Error do
    # ...
  end

  after_action do
    raise FooError unless is_authorized?

    # or raise Policy::Error
    is_authorized!
  end

  def show
    @post = Post.find_by id: params[:id]

    authorize @post.can.write?            # can current user write @post model
    authorize DashboardPolicy.can.access? # can current user access dashboard, checked in DashboardPolicy
  end
```

Of course you can allways use "bare bones" checks.

```ruby
  @post.can.read? { redirect_to '/', info: 'No access for you!' }

  # or as one liner, because success returns @model
  @post = Post.find_by(id: params[:id]).can.read? do
    redirect_to '/'
  end
```

## How to create and name a policy class

Rules

* Policy class have to inherit from `Policy`
* Policy class is calculated based on a given model
  * with `@post` (`class Post`) model given, `PostPolicy` class will be used
  * with `@foo_bar` (`class Foo::Bar`) model given, `Foo::BarPolicy` class will be used
  * with `:foo` (`Symbol`) model given , `FooPolicy` class will be used
* Policy methods end with question mark, raise errors and return `true` or `false` (`def read?`)
  * if you need to raise policy named error, use `error` method (`error 'max 10 records per hour allowed'`)

#### Full example

```ruby
class BlogPolicy < Policy
  COUNT = 100

  def before(action_name)
    return user.is_admin ? true : false
  end

  def create?(ip)
    if Blog.where(ip: ip).count < COUNT
      true
    else
      error "Only #{COUNT} blogs can be created per uniqe IP"
    end
  end

  def read?
    return true if model.created_by == user.id
    model.is_published
  end

  def update?
    model.created_by == user.id
  end

  def delete?
    model.is_published?
  end
end
```

## Model can helper - cleaner code, full example

This is how can helper on models is implemented.

```ruby
# ActiveRecord or Sequel class
class Blog < ApplicationModel
end

# small proxy method to create policy scope from model
class ApplicationModel
  def can(user = nil)
    Policy.can(user: user, model: self)
  end
end

# Blog policy object
class BlogPolicy
  def read?
    return true if model.is_published           # all can read if published
    return true if model.created_by == user.id  # unless published, only creator can see
    false
  end
end

# then this will work everywhere
@blog = Blog.first
@blog.can.read? # true or false
@blog.can.read! # true or raise Policy::Error
@blog.can.read! do |error_message|
  # true or execute block if false
end
```

## Before filter

It is possible to define before and after filter for any action.

* If before filter returns true, action method will not be called.
* If after filter returns false, succesufful policy check will be overriden.

#### Before filter example

```ruby
class ModelPolicy
  def before action
    # admin can do anything
    @user.is_admin
  end
end

class PostPolicy < ModelPolicy
  def read?
    error 'noope'
  end
end

Policy.can(@post, user: admin_user).read? # before filter returns true, error is never called
Policy.can(@post, user: user).read?       # not allowed, raises error
```

## Defining global current user

Maybe you have defined current user for a current request. If you do, you do not have to pass it arround all the time.

```ruby
# insted
@policy = BlogPolicy.can(@blog, current_user).can.read?
# you can write
@policy = BlogPolicy.can(@blog).can.read?

# or inline
@blog.can(@user).read?
@blog.can.read?
```

Clear policy will try to load current by calling `Policy#current_user`. Feel free to overload the method to meet your needs.

```ruby
class Policy
  # default current_user policy method
  def current_user
    if defined?(User) && User.respond_to?(:current)
      User.current
    elsif defined?(Current) && Current.respond_to?(:user)
      Current.user
    elsif user = Thread.current[:current_user]
      user
    else
      raise RuntimeError.new('Current user not found in Policy#current_user')
    end
  end
end
```

## Model scopes

Often, you will want to have some kind of view listing records which a particular user has access to. (line taken from Pundit gem)

When using Policy, you are expected to define methods in model (class methods in ActiveRecods and DatabasetMethods in Sequel)
and NOT in Policy object, because Policy object is A WRONG place for that logic.

Use something like this

```ruby
# inside model
class Blog
  def self.editable_by user
    if Policy.can(user: user).admin?
      # no limit if it can admin, return all records
      self
    else
      # else return only records created by user
      where(created_by: user.id)
    end
  end
end

Blog.editable_by(current_user).where(...)
```

### Using `.can ` shortcut

Unless `current_user` is defined, it will be read from global state if possible.

```ruby
# try User.current || Current.user
@post.can.update?

# or pass the user model
@post.can(@user).update?

# translates to
Policy.can(model: @post, user: @user, class: PostPolicy).update?
```

## Headless policies

Given there is a policy without a corresponding model / ruby class, you can retrieve it by passing a symbol.

```ruby
# app/policies/dashboard_policy.rb
class DashboardPolicy < Policy
  def access?
    user.orgs_that_user_can_manage.count > 0
  end
end
```

```ruby
# In controllers
authorize :dashboard, :access?

# In views
<% if DashboardPolicy.can.access? %>
  <%= link_to 'Dashboard', dashboard_path %>
<% end %>
```

## Defaults

This are policy defautls for fallback policy and current user finder. Feel free to modify or disable any option.

```ruby
# If loading policy via Policy.can @foo, if FooPolicy is not found it will fallback to ModelPolicy
Policy.set :fallback_policy, 'ModelPolicy'

# if you use define your current user in Thread.current, you can fetch it here
Policy.set :current_user do
  if defined?(User) && User.respond_to?(:current)
    User.current
  elsif defined?(Current) && Current.respond_to?(:user)
    Current.user
  else
    raise RuntimeError.new('User not defined and current user not found')
  end
end
```

## Dependency

none

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rspec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dux/egoist.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
