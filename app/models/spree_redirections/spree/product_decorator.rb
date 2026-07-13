# frozen_string_literal: true

module SpreeRedirections
  module Spree
    module ProductDecorator
      def create_redirection(from, to, type, product_id, locale, published = true) # rubocop:disable Metrics/ParameterLists
        old_url = "/#{locale}/p/#{from}"
        new_url = "/#{locale}/#{type}/#{to}"
        store_url = ENV.fetch('FRONT_URL', nil)
        manage_redirections_on_republish(new_url, store_url, product_id) if published
        check_for_loops(new_url, store_url)
        redirection = ::SpreeRedirections::Redirection.new(
          store_url:,
          old_url:,
          new_url:,
          http_status: 301,
          spree_product_id: product_id,
          redirection_type: type
        )

        redirection.save!
      rescue StandardError
        true
      end

      def check_for_loops(new_url, store_url)
        existing_redirection = ::SpreeRedirections::Redirection.find_by(old_url: new_url, store_url:)
        return if existing_redirection.nil?

        existing_redirection.delete
      end

      def redirect_from_destroyed_product(product_id, locale)
        I18n.with_locale(locale) do
          taxon_permalink = taxons.order(:lft).filter_map(&:permalink).last
          destroyed_product_slug = translations.where(locale:)&.first&.slug
          return if destroyed_product_slug.nil? || taxon_permalink.nil?

          create_redirection(destroyed_product_slug, taxon_permalink, 't', product_id, locale, false)
        end
      end

      def remove_old_friendly_id_slugs(new_slug = nil)
        slugs.where.not(slug: new_slug || slug).delete_all
      end

      # When a product has been republished with a new slug-change old slug-> taxon redirection to old_slug -> new_slug
      def manage_redirections_on_republish(new_url, store_url, product_id)
        existing_redirection = ::SpreeRedirections::Redirection.where(spree_product_id: product_id,
                                                                      store_url:).order(:id).first
        return if existing_redirection.nil? || existing_redirection.new_url == new_url

        existing_redirection.update(new_url:, redirection_type: 'p')
      end

      # When product has been republished with the same slug
      # Existing taxon redirection means the product was unpublished before and for some reason
      # The taxon redirection is still present in the database
      def check_for_outdated_taxon_redirection(slug, spree_product_id, locale)
        store_url = ENV.fetch('FRONT_URL', nil)
        old_url = "/#{locale}/p/#{slug}"

        existing_redirection = ::SpreeRedirections::Redirection.where(old_url:,
                                                                      spree_product_id:, store_url:, redirection_type: 't')
        return if existing_redirection.blank?

        existing_redirection.delete_all
      end
    end
  end
end

Spree::Product.prepend SpreeRedirections::Spree::ProductDecorator
