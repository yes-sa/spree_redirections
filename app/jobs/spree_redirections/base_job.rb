# frozen_string_literal: true

module SpreeRedirections
  class BaseJob < Spree::BaseJob
    queue_as SpreeRedirections.queue
  end
end
