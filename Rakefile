require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
require 'spree/testing_support/extension_rake'

RSpec::Core::RakeTask.new

task :default do
  if Dir['spec/dummy'].empty?
    Rake::Task[:test_app].invoke
    Dir.chdir('../../')
  end
  Rake::Task[:spec].invoke
end

desc 'Generates a dummy app for testing'
task :test_app do
  ENV['LIB_NAME'] = 'spree_redirections'
  Rake::Task['extension:test_app'].invoke
  root_gemfile = File.expand_path('Gemfile', __dir__)
  bundle_env = { 'BUNDLE_GEMFILE' => root_gemfile, 'RAILS_ENV' => 'test' }
  Dir.chdir(File.join(__dir__, 'spec/dummy')) do
    system(bundle_env, 'bundle exec rails railties:install:migrations') || raise('Failed to install engine migrations')
    Dir.glob('db/migrate/*.{acts_as_taggable_on_engine,action_mailbox}.rb').each { |f| File.delete(f) }

    system(bundle_env, 'bundle exec rails db:migrate') || raise('Failed to migrate dummy app database')
  end
end
