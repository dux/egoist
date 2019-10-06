# Ruby access policy library

## Installation and usage

to install

`gem install clean-policy`

or in Gemfile

`gem 'clean-policy'`

and to use

`require 'clean-policy'`

## Scopes

Often, you will want to have some kind of view listing records which a particular user has access to.
When using CleanPolicy, you are expected to define methods in model (class methods in ActiveRecods and DatabasetMethods in Sequel)
and NOT in Policy object, because Policy object is a wrong place to store that methods.

Use something like this

```ruby
  # inside model
  class Blog
    def self.editable user
      if policy(user: user).admin?
        # no limit if it can admin
        self
      else
        # else return only records created by user
        where(created_by: user.id)
      end
    end
  end
```

### Dependency

none

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rspec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/solnic/clean-policy.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
