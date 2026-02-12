# frozen_string_literal: true

module SpreeRedirections
  class Redirection < ApplicationRecord
    validates :http_status, :old_url, :new_url, :store_url, presence: true
    validates :old_url,
              uniqueness: {
                scope: :store_url,
                conditions: -> { where(deleted_at: nil) },
                message: I18n.t('spree.redirection.errors.uniqueness_for_store_url')
              }, format: {
                with: %r{\A/[a-zA-Z0-9/\-_?&=]*\z},
                message: I18n.t('spree.redirection.errors.relative_old_url')
              }
    validate :correct_http_status
    validate :existing_store
    validate :external_new_url_format
    validate :not_admin_redirection

    default_scope -> { where(deleted_at: nil).order(created_at: :desc) }
    scope :with_archival, -> { unscoped.where.not(deleted_at: nil).order(deleted_at: :desc) }

    def destroy(current_user:)
      update(deleted_at: Time.current, deleted_by: current_user)
    end

    def self.ransackable_attributes(_auth_object = nil)
      %w[id old_url new_url http_status external_redirection created_at created_by updated_at deleted_at deleted_by]
    end

    def self.model_name
      ActiveModel::Name.new(self, nil, 'Redirection')
    end

    private

    def correct_http_status
      return if %w[301 302 303].include?(http_status)

      errors.add(:http_status, I18n.t('spree.errors.invalid_http_status'))
    end

    def existing_store
      return if Spree::CustomDomain.find_by(url: store_url).present?

      errors.add(:store_url, I18n.t('spree.errors.store_not_found'))
    end

    def external_new_url_format
      return if new_url.blank? || !external_redirection

      allowed_prefixes =
        if Rails.env.development?
          %w[http://www. https://www.]
        else
          %w[https://www.]
        end

      return if allowed_prefixes.any? { |prefix| new_url.start_with?(prefix) }

      errors.add(:new_url, I18n.t('spree.redirection.errors.invalid_url'))
    end

    def not_admin_redirection
      return unless /admin/i.match?(old_url) || /admin/i.match?(new_url)

      errors.add(:base, I18n.t('spree.redirection.errors.redirection_to_admin'))
    end
  end
end
