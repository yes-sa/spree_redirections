# frozen_string_literal: true

module SpreeRedirections
  module Spree
    module ProductDecorator
      # def self.prepended(base)
      #   base.before_destroy :redirect_from_destroyed_product, prepend: true
      #   base.before_update :redirect_from_old_slug, prepend: true
      #   base.after_update :remove_old_friendly_id_slugs, if: :saved_change_to_slug?, prepend: true
      # end

      def create_redirection(from, to, type, published = true)
        old_url = "/#{I18n.locale}/p/#{from}"
        new_url = "/#{I18n.locale}/#{type}/#{to}"
        store_url = ENV.fetch('FRONT_URL', nil)
        manage_redirections_on_republish(old_url, new_url, store_url) if published
        check_for_loops(new_url, store_url)
        redirection = ::SpreeRedirections::Redirection.new(
          store_url: store_url,
          old_url: old_url,
          new_url: new_url,
          http_status: 301
        )

        redirection.save!
      end

      def check_for_loops(new_url, store_url)
        existing_redirection = ::SpreeRedirections::Redirection.find_by(old_url: new_url, store_url:)
        return if existing_redirection.nil?

        existing_redirection.destroy(current_user: 'products worker')
      end

      def redirect_from_destroyed_product
        taxon_permalink = taxons.order(:lft).filter_map(&:permalink).last
        return if slug.nil? || taxon_permalink.nil?

        create_redirection(slug, taxon_permalink, 't', false)
      end

      def remove_old_friendly_id_slugs(new_slug = nil)
        slugs.where.not(slug: new_slug || slug).delete_all
      end

      def redirect_from_old_slug
        return unless will_save_change_to_slug?

        old_slug, new_slug = slug_change_to_be_saved
        return if old_slug.blank? || new_slug.blank?

        create_redirection(old_slug, new_slug, 'p')
      end

      # When product has been republished with new slug
      def manage_redirections_on_republish(old_url, new_url, store_url)
        existing_redirection = ::SpreeRedirections::Redirection.find_by(old_url:, store_url: store_url)
        return if existing_redirection.nil? || existing_redirection.new_url == new_url

        existing_redirection.destroy(current_user: 'products worker')
      end

      # When product has been republished with the same slug
      def check_for_outdated_taxon_redirection(slug)
        store_url = ENV.fetch('FRONT_URL', nil)
        old_url = "/#{I18n.locale}/p/#{slug}"

        existing_redirection = ::SpreeRedirections::Redirection.find_by(old_url:, store_url:)
        segments = existing_redirection.new_url.split('/').compact_blank
        return unless segments[1] == 't' # taxon redirection means the product was unpublished before

        existing_redirection.destroy(current_user: 'products worker')
      end
    end
  end
end

Spree::Product.prepend SpreeRedirections::Spree::ProductDecorator
