module SpreeRedirections
  class Redirection < ActiveRecord::Base
    validates :http_status, :old_url, :new_url, :store_id, presence: true
    validate :correct_http_status

    default_scope -> { where(deleted_at: nil).order(created_at: :desc) }
    scope :with_archival, -> { unscoped }

    def destroy
      update!(deleted_at: Time.current)
    end

    private

    def correct_http_status
      return if %w[301 302 303].include?(self.http_status)

      errors.add(:base, I18n.t('spree.errors.invalid_http_status'))
    end
  end
end
