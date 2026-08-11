# frozen_string_literal: true

module Spree
  module Imports
    module RowProcessors
      class Redirection < Base
        def process!
          redirection = find_or_initialize_redirection
          assign_redirection_attributes(redirection)
          redirection.save!
          redirection
        end

        private

        def find_or_initialize_redirection
          store_url = attributes['store_url'].to_s.strip
          old_url = attributes['old_url'].to_s.strip
          raise ArgumentError, 'Store URL is required' if store_url.blank?
          raise ArgumentError, 'Old URL is required' if old_url.blank?

          ::SpreeRedirections::Redirection.find_or_initialize_by(store_url: store_url, old_url: old_url)
        end

        def assign_redirection_attributes(redirection)
          redirection.new_url = attributes['new_url'].to_s.strip
          redirection.http_status = attributes['http_status'].to_s.strip
          if attributes['external_redirection'].present?
            redirection.external_redirection = to_boolean(attributes['external_redirection'])
          end
          redirection.created_by = created_by_name
        end

        def created_by_name
          import.user.respond_to?(:full_name) ? import.user.full_name : import.user&.email
        end

        def to_boolean(value)
          value.to_s.strip.downcase.in?(%w[true yes 1 y])
        end
      end
    end
  end
end
