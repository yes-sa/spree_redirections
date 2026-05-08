module SpreeRedirections
  module Spree
    module ProductDecorator
      def self.prepended(base)
        base.before_destroy :redirect_from_destroyed_product, prepend: true
        base.before_update :redirect_from_old_slug, prepend: true
      end

      private

      def redirect_from_destroyed_product
        taxon_permalink = taxons.order(:lft).filter_map{ |x| x.permalink}.last
        return if slug.nil? || taxon_permalink.nil?

        create_redirection(taxon_permalink)
      end

      def redirect_from_old_slug
        taxon_permalink = taxons.order(:lft).filter_map{ |x| x.permalink}.last
        return unless slug.changed?
        return if slug.nil? || taxon_permalink.nil?

        create_redirection(taxon_permalink)
      end

      def create_redirection(taxon_permalink)
        old_url = "/#{I18n.locale.to_s}/p/#{slug}"
        new_url = "/#{I18n.locale.to_s}/t/#{taxon_permalink}"
        store_url = ENV['FRONT_URL']
        redirection = ::SpreeRedirections::Redirection.new(
          store_url:,
          old_url:,
          new_url:,
          http_status: 301
        )
        redirection.save!
      end
    end
  end
end

Spree::Product.prepend SpreeRedirections::Spree::ProductDecorator
