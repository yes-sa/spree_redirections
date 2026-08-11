# frozen_string_literal: true

require 'spree_core'
require 'spree_extension'
# Provides Spree::CustomDomain (Redirection#existing_store validates store_url against
# it). Bundler.require only auto-requires gems with an explicit Gemfile entry, not
# dependencies declared solely in our own gemspec, so we require them ourselves here.
require 'spree_custom_domains'
require 'spree_multi_store'
require 'spree_redirections/engine'
require 'spree_redirections/version'
require 'spree_redirections/configuration'

module SpreeRedirections
  mattr_accessor :queue

  def self.queue
    @@queue ||= Spree.queues.default
  end
end
