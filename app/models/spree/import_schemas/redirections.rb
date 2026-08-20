# frozen_string_literal: true

module Spree
  module ImportSchemas
    class Redirections < Spree::ImportSchema
      FIELDS = [
        { name: I18n.t('spree.redirection.import.field_names.store_url'), label: I18n.t('spree.redirection.store_url'), required: true },
        { name: I18n.t('spree.redirection.import.field_names.old_url'), label: I18n.t('spree.redirection.old_url'), required: true },
        { name: I18n.t('spree.redirection.import.field_names.new_url'), label: I18n.t('spree.redirection.new_url'), required: true },
        { name: I18n.t('spree.redirection.import.field_names.http_status'), label: I18n.t('spree.redirection.http_status'), required: true },
        { name: I18n.t('spree.redirection.import.field_names.external_redirection'), label: I18n.t('spree.redirection.external_redirection') }
      ].freeze
    end
  end
end
