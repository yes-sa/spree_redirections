# frozen_string_literal: true

module Spree
  module ImportSchemas
    class Redirections < Spree::ImportSchema
      FIELDS = [
        { name: 'store_url', label: 'Store URL', required: true },
        { name: 'old_url', label: 'Old URL', required: true },
        { name: 'new_url', label: 'New URL', required: true },
        { name: 'http_status', label: 'HTTP Status', required: true },
        { name: 'external_redirection', label: 'External Redirection' }
      ].freeze
    end
  end
end
