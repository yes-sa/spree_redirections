# frozen_string_literal: true

module SpreeRedirections
  class Redirection < ApplicationRecord
    validates :http_status, :old_url, :new_url, :store_url, presence: true
    validate :correct_http_status
    validate :existing_store

    default_scope -> { where(deleted_at: nil).order(created_at: :desc) }
    scope :with_archival, -> { unscoped }

    def destroy
      update!(deleted_at: Time.current)
    end

    def self.ransackable_attributes(_auth_object = nil)
      %w[id old_url new_url http_status external_redirection created_at updated_at deleted_at]
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
  end
end
