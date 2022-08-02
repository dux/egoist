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

## Idead

Egoist tries to provide simple answer to question: can this user perform this action on this object.

## How to use

Common usage is to use it directly on the model

```ruby
class CompanyPolicy < Policy
  def read?
    model.created_by == user.id
  end
end

# if you define current user in current thread
@commpany.can.read?           # returns true / false

# if you want to pass in user and pass for generic user
@commpany.can(@user).read?    # returns true / false

# if you want to raise Policy::Error use bang
@commpany.can(@user).read!    # returns @commpany / raise Policy::Error

# if you want to do a specific action if policy check fails, use block (works for ? and ! methods)
@commpany.can(@user).read? do |error_message| # returns true or raise error
  redirect_to '/', error: 'You are not allowed to access this company'
end
```

## Full annotated example

More complex example that presents all features

```ruby
# base model policy
class ModelPolicy < Policy
  # before runs before any action, if it returns true, action is allowed
  #   and usefull to give full permissions to admins in small apps. 
  def before action
    if action != :delete?
      # access user via user or @user 
      return true if user.can.admin?
    end
  end

  def read?
    true
  end

  def update?
    # access model via model or @model
    return true if model.created_by == user.id
  end
end

class CompanyPolicy < ModelPolicy
  # @company.can.create?
  def create?
    company_count = Company.where(created_by: user.id).where('created_at>?', Time.now - 1.day).count

    if company_count > 10
      # do not allow more then 10 companies per day
      error 'You are allowed to create max 10 companies per day'
    else
      true
    end
  end

  # @company.can.read?
  def read?
    # access model via model or @model
    model.created_by == user.id
  end

  # @company.can.update?
  def update?
    # check if user is company manager
    return true if model.is_company_manager?(user)
  
    # call ModelPolicy#update?
    super
  end
end

class BlogPolicy < Policy
  COUNT = 1000

  # you can pass params to policy checks
  # @blog = Blog.new title: 'Test'
  # @blog.can.create?(request.ip)
  def create?(ip)
    if Blog.where(ip: ip).count < COUNT
      true
    else
      error "Only #{COUNT} blogs can be created per uniqe IP"
    end
  end
end

class UserPolicy < ModelPolicy
  # @user.can.update?
  def update?
    # you are not allowed to make yourself admin
    error 'You are not allowed to make yourself admin' if model.is_admin

    # you are not allowed to cahange email
    error 'Action not allowed' if model.changed?(:email)

    # you can update yourself
    return true if model.created_by == user.id

    # admins can update all users and that is handled in before filter
    # for all other useages -> not allowed
    false
  end

  # @user.can.destroy?
  def destroy?
    # users are not allowed to be destryed in any case
    false
  end

  # @user.can.admin?
  def admin?
    # if user has attribute is_admin set to true, he can admin
    # model is ignored in this case
    user.is_admin == true
  end
end

###

class ApplicationModel
  include Policy::Model
end

@company = Company.find(123)

# full init
CompanyPolicy.new(user: @user, model: @company).can.update?

# or 
@company.can(@user).update?

# or assuming User.current == @user
@company.can.update?
```

## Opitons to check for permission

```ruby
@policy = SomePolicy.new(model: @some_model, user: @some_user).can
```

* `@policy.read?`

  this will return `truthy` value (`@model` or `true`) or `nil`.

*  `@policy.read!`

   If you bang! method instead of question mark, Policy will raise error instead of returning `nil`.

* `@policy.read? { redirect_to '/' } or @policy.read! { redirect_to '/' }`

  If you provide a `&block`, `&block` will be executed first and then `nil` will be retuned.


That is all you need to know for calling policies.

## Main difference to popular lib - Pundit

* exposes friendly can method for models `@model.can.update?`
  * you can use question mark to return boolean `@model.can(@user).update?` (`true`, `false`)
  * you can use bang! `@model.can(@user).update!`, which will raise `Policy::Error` error on `false`
  * If you want to expose thread current user (anti-pattern for many rubisits) you can use shorthand
    `@model.can.update!`

* you can pass block to policy check which will be evaluated on `false` policy check `@model.can.read? { redirect_to '/' }`

* exposes global `Policy` method, for easier access from where ever you need it `Policy.can(model: @model, user: @user).read?` (uses User.current or Current.user, can be customized)

* In `Policy` classes allows `before` filter to be defined. If it returns true, policy is not checked

* allows current user to be defined. Instead of `@model.can(current_user).update?` becomes "cleaner" `@model.can.update?`

* allows customized error messages `error('You are not allowed to make yourself admin')`
  `https://github.com/varvet/pundit/issues/654`

* does not support Scope (Active::Record) anti-pattern. Define your scopes inside a models using policy checks

* allows passing of parameters to policy checks. This is anti-pattern, but sometimes is needed

## Controllrers and authorizations

Authorization check after the request is done, is basicly a rutime policy check. Use it in dashboards.

* you can pass only model, user, optional class and ability to test. It allways follows the same pattern: Can "this" user perform "this" action on "this" model? - clean!

* `auhthorize(@model, :read?)` or `auhthorize(@model, :read?)` will authorize model action and raise `Policy::Error` unlless one available.
* `is_authorized?` will return `true` or `false`.
* `is_authorized!` will raise `Policy::Error` unless authorized.

```ruby
class BaseController
  include Policy::Controller
end

class Dashboard::PostsController < BaseController
  rescue_from Policy::Error do
    # ...
  end

  after_action do
    unless is_authorized?
      raise Policy::Error.new('Custom message') 
    end

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

## How to write a policy class

Rules

* Policy class have to inherit from `Policy`
* Policy class is calculated based on a given model
  * with `@post` (`class Post`) model given, `PostPolicy` class will be used
  * with `@foo_bar` (`class Foo::Bar`) model given, `Foo::BarPolicy` class will be used
  * with `:foo` (`Symbol`) model given , `FooPolicy` class will be used
* Policy methods end with question mark, raise errors and return `true` or `false` (`def read?`)
  * if you need to raise policy named error, use `error` method (`error 'max 10 records per hour allowed'`)

## Overloads

You can customize a way current_user is fetched inside Egoist.

```ruby
def Policy.current_user
  Thread.current[:my_current_user]
end

# now insted full
BlogPolicy.new(@blog, current_user).can.read?
# or simplified
BlogPolicy.can(@blog, current_user).read?

# you can write
BlogPolicy.can(@blog).can.read?
# or autload BlogPolicy via useage of base class
Policy.can(@blog).can.read?

# or even shorter
@blog.can.read?

# we came from 
BlogPolicy.new(@blog, current_user).can.read?
# to
@blog.can.read?
# beautiful!
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
