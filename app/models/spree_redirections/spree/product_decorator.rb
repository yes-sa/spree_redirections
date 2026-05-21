# frozen_string_literal: true

module SpreeRedirections
  module Spree
    module ProductDecorator
      def self.prepended(base)
        base.before_destroy :redirect_from_destroyed_product, prepend: true
        base.before_update :redirect_from_old_slug, prepend: true
        base.after_update :remove_old_friendly_id_slugs, if: :saved_change_to_slug?, prepend: true
      end

      private

      def redirect_from_destroyed_product
        taxon_permalink = taxons.order(:lft).filter_map(&:permalink).last
        return if slug.nil? || taxon_permalink.nil?

        create_redirection(slug, taxon_permalink, 't')
      end

      def remove_old_friendly_id_slugs
        slugs.where.not(slug: slug).delete_all
      end

      def redirect_from_old_slug
        return unless will_save_change_to_slug?

        old_slug, new_slug = slug_change_to_be_saved
        return if old_slug.blank? || new_slug.blank?

        create_redirection(old_slug, new_slug, 'p')
      end

      def create_redirection(from, to, type)
        old_url = "/#{I18n.locale}/p/#{from}"
        new_url = "/#{I18n.locale}/#{type}/#{to}"
        store_url = ENV.fetch('FRONT_URL', nil)

        redirection = ::SpreeRedirections::Redirection.new(
          store_url: store_url,
          old_url: old_url,
          new_url: new_url,
          http_status: 301
        )

        redirection.save!
      end
    end
  end
end

Spree::Product.prepend SpreeRedirections::Spree::ProductDecorator
