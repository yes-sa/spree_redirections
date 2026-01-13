# encoding: UTF-8
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'spree_redirections/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_redirections'
  s.version     = SpreeRedirections::VERSION
  s.summary     = "Spree Commerce Redirections Extension"
  s.required_ruby_version = '>= 3.0'

  s.author    = 'Tomasz Strzeszewski'
  s.email     = 'tomasz.strzeszewski.s@gmail.com'
  s.homepage  = 'https://github.com/your-github-handle/spree_redirections'
  s.license = 'AGPL-3.0-or-later'

  s.files        = Dir["{app,config,db,lib,vendor}/**/*", "LICENSE.md", "Rakefile", "README.md"].reject { |f| f.match(/^spec/) && !f.match(/^spec\/fixtures/) }
  s.require_path = 'lib'
  s.requirements << 'none'

  spree_opts = '~> 5.2'
  s.add_dependency 'spree', spree_opts
  s.add_dependency 'spree_api', spree_opts
  s.metadata['rubygems_mfa_required'] = 'true'

  s.add_dependency 'spree_extension'
  s.add_dependency 'rspec-rails'
  s.add_dependency 'rubocop-rspec'
  s.add_dependency 'rails', '~> 7.2'

  s.add_development_dependency 'spree_dev_tools'
end
