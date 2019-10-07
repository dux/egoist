# Ruby access policy library

## Installation and usage

to install

`gem install clean-policy`

or in Gemfile

`gem 'clean-policy'`

and to use

`require 'clean-policy'`

## How to use

Basic usage is to load policy object and execute test

`Policy(user: current_user, model: @blog).can.read?`

this will return `true` or `false`.

If you bang! method instead of question mark, Policy will raise error instead of returning false.

`Policy(user: current_user, model: @blog).can.read!`

### How to create and name a policy class

Rules

* Policy class have to inherit from `Policy`
* Policy class is calculated based on a given model
  * if no model given, `ApplicationPolicy` will be used
  * with @post (class Post) model given, `PostPolicy` class will be used
  * with @foo_bar (class Foo::Bar) model given, `Foo::BarPolicy` class will be used

Example

```ruby
class BlogPolicy < Policy
  def before(action_name)
    return @user.is_admin ? true : false
  end

  def create?(ip)
    Blog.where(ip: ip).count < 100
  end

  def read?
    return true if @model.created_by == @user.id
    @model.is_published
  end

  def update?
    @model.created_by == @user.id
  end

  def delete?
    @model.is_published
  end
end
```

## Model helper - cleaner code

if you modify `ApplicationModel` and create method `can`, that also auto load current user you can have a nifty code.

```ruby
class ApplicationModel
  def can
    Policy(user: User.current, model: self) ? self : nil
  end
end

class Post < ApplicationModel
end
```

then this will work everywhere

```ruby
  @post = Post.first
  @post.can.read? # true or false
  @post.can.read! # true or raise Policy::Error
  @post.can.read! do |error|
    # true or execute block if false
  end
```

## Before filter

It is possible to define before filter for any action. If before filter returns true, action method will not be called.

#### Before filter example

```ruby
class ModelPolicy
  def before action
    # admin can do anything
    return true if @user.is_admin
  end
end

class PostPolicy < ModelPolicy
  def read?
    error 'noope'
  end
end

Policy(user: admin_user).can.read? # before filter returns true, error is never called
Policy(user: user).can.read?       # not allowed, raises error
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
      if Policy(user: user).admin?
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

## Usage in controllers

There is no controller policy method matching because

* that is not needed
* is confusing and produces unnecessary code

Unnecessary doube code == code code smell, and code that smells is not clean.

What you should do is try to use basic CRUD actions (create, read, update, delete) as much as possible.

For example let say that you have a `@contract` that is not for everybodys eyes and you have api action
to fetch some data + view controller actions to show that data.

You will not create `show?`, `show_documents?`, `quote?` methods in `QuotePolicy` and `ApiPolicy`, but you will ony create one, `read?` method in `ContractPolicy` and that is all.

Then you write something like

* `@contract.can.read!` - `Policy::Error` will be raised unless a user can read a docuent
* `return redirect_to '/' unless @contract.can.read?`
* or written like this even `@contract.can.read! { return redirect_to '/' }`

We allways check for read permission, when we need to check for read permision. No need to double define controller methods in `Policy` object.

### Dependency

none

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rspec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dux/clean-policy.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
