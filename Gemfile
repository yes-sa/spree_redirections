# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gemspec

group :development, :test do
  gem 'brakeman'
  gem 'byebug'
  gem 'rubocop', '~> 1.79', '>= 1.79.2'
  gem 'rubocop-rails', '~> 2.33', '>= 2.33.3'
  gem 'rubocop-rails-omakase'
  gem 'spree_dev_tools'
  gem 'sqlite3', '>= 2.0'
end

group :test do
  spree_opts = '~> 5.2'
  gem 'abbrev'
  gem 'factory_bot_rails'
  gem 'ffaker'
  gem 'observer'
  gem 'rails-controller-testing'
  gem 'spree', spree_opts
  gem 'spree_admin', spree_opts
  gem 'spree_emails', spree_opts
  gem 'spree_storefront', spree_opts
  gem 'webmock'
end

gem 'sprockets-rails', '~> 3.5'
