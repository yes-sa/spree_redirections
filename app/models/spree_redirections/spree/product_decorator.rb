# frozen_string_literal: true

module SpreeRedirections
  module Spree
    module ProductDecorator
      def self.prepended(base)
        base.after_update_commit :handle_product_status_transition, if: :saved_change_to_status?
      end

      def create_redirection(from, to, type, product_id, locale, published = true)
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
        taxon_permalink = taxons.order(:lft).filter_map(&:permalink).last
        return if slug.nil? || taxon_permalink.nil?

        create_redirection(slug, taxon_permalink, 't', product_id, locale, false)
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

      # Redirect from archived or drafted product
      def handle_product_status_transition
        old_status, new_status = saved_change_to_status

        return if old_status == new_status

        if active? && in_stock?
          remove_all_locales_redirections
        else
          create_all_locales_redirections
        end
      end

      def handle_product_stocks_change(product_stock_state)
        if product_stock_state && active?
          remove_all_locales_redirections
        else
          create_all_locales_redirections
        end
      end

      private

      def create_all_locales_redirections
        translations.each do |translation|
          locale = translation.locale
          I18n.with_locale(locale) do
            redirect_from_destroyed_product(id, locale)
          end
        end
      end

      def remove_all_locales_redirections
        translations.each do |translation|
          locale = translation.locale
          I18n.with_locale(locale) do
            check_for_outdated_taxon_redirection(slug, id, locale)
          end
        end
      end
    end
  end
end

Spree::Product.prepend SpreeRedirections::Spree::ProductDecorator
