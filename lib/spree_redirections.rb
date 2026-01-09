require 'spree_core'
require 'spree_extension'
require 'spree_redirections/engine'
require 'spree_redirections/version'
require 'spree_redirections/configuration'

module SpreeRedirections
  mattr_accessor :queue

  def self.queue
    @@queue ||= Spree.queues.default
  end
end
