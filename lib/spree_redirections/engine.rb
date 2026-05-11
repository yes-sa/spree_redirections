# frozen_string_literal: true

module SpreeRedirections
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_redirections'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer 'spree_redirections.environment', before: :load_config_initializers do |_app|
      SpreeRedirections::Config = SpreeRedirections::Configuration.new
    end

    initializer 'spree_redirections.assets' do |app|
      app.config.assets.paths << root.join('app/javascript')
      app.config.assets.paths << root.join('vendor/javascript')
      app.config.assets.paths << root.join('vendor/stylesheets')
      app.config.assets.precompile += %w[spree_redirections_manifest]
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare(&method(:activate).to_proc)
  end
end
