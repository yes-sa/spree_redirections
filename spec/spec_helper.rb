# frozen_string_literal: true

# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require 'dotenv/load'

require File.expand_path('dummy/config/environment.rb', __dir__)

require 'spree_redirections/factories'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

def json_response
  case body = JSON.parse(response.body)
  when Hash
    body.with_indifferent_access
  when Array
    body
  end
end
