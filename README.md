# Spree Redirections

This is a Redirections extension for [Spree Commerce](https://spreecommerce.org), an open source e-commerce platform built with Ruby on Rails.

## Installation

1. Add this extension to your Gemfile with this line:

    ```ruby
    bundle add spree_redirections
    ```

2. Run the install generator

    ```ruby
    bundle exec rails g spree_redirections:install
    ```

3. Restart your server

  If your server was running, restart it so that it can find the assets properly.

4. Add to your application.rb:
on top:
```ruby
require 'middleware/spree_redirections/redirections_middleware'
```
and in config:
```ruby
config.middleware.insert_after 0, RedirectionsMiddleware
```
## Developing

1. Create a dummy app

    ```bash
    bundle update
    bundle exec rake test_app
    ```

2. Add your new code
3. Run tests
Remember to generate dummy app first
```shell
   bundle exec rake test_app
```
then

```bash
   bundle exec rspec
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_redirections/factories'
```
4. To test manually run server in development mode and set SERVER_NAME_IMITATION env variable to mock your store server name 

## Releasing a new version

```shell
bundle exec gem bump -p -t
bundle exec gem release
```

For more options please see [gem-release README](https://github.com/svenfuchs/gem-release)

## Contributing

If you'd like to contribute, please take a look at the
[instructions](CONTRIBUTING.md) for installing dependencies and crafting a good
pull request.
