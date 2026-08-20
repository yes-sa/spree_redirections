# frozen_string_literal: true

module Spree
  module Imports
    module RowProcessors
      class Redirection < Base
        class InvalidRow < StandardError; end

        # Accepted spellings for the external_redirection column, mapped to the boolean
        # they cast to. Both languages are accepted regardless of the admin's active
        # locale: the CSV's language is a property of the file, not of whoever happens to
        # be running the import. "falsz" is here because the diacritic in "fałsz" is easy
        # to lose when a file is typed or re-encoded.
        BOOLEAN_VALUES = {
          'true' => true, 't' => true, 'yes' => true, 'y' => true, '1' => true,
          'prawda' => true, 'tak' => true,
          'false' => false, 'f' => false, 'no' => false, 'n' => false, '0' => false,
          'falsz' => false, 'fałsz' => false, 'nie' => false
        }.freeze

        def process!
          redirection = find_or_initialize_redirection
          assign_redirection_attributes(redirection)
          # join, not to_sentence: the latter's connector comes from a support.array key
          # that has no Polish translation, so it splices an English "and" into the message.
          raise InvalidRow, redirection.errors.full_messages.join(', ') unless redirection.save

          redirection
        end

        private

        def find_or_initialize_redirection
          store_url = attributes['store_url'].to_s.strip
          old_url = attributes['old_url'].to_s.strip
          raise InvalidRow, I18n.t('spree.redirection.import.errors.store_url_missing') if store_url.blank?
          raise InvalidRow, I18n.t('spree.redirection.import.errors.old_url_missing') if old_url.blank?

          ::SpreeRedirections::Redirection.find_or_initialize_by(store_url: store_url, old_url: old_url)
        end

        def assign_redirection_attributes(redirection)
          redirection.new_url = attributes['new_url'].to_s.strip
          redirection.http_status = attributes['http_status'].to_s.strip
          assign_external_redirection(redirection)
          redirection.created_by = created_by_name
        end

        # Only touches the flag when the CSV row actually maps it, so a re-import that
        # omits this column doesn't clobber an existing redirection's current value
        # (and a brand new one falls back to the column's `default: false`).
        def assign_external_redirection(redirection)
          raw = attributes['external_redirection']
          return if raw.blank?

          redirection.external_redirection = cast_boolean(raw)
        end

        # Fails the row rather than quietly treating anything unrecognised as false --
        # a typo silently importing the opposite of what the file says is worse than an
        # error the admin can see and correct.
        def cast_boolean(raw)
          BOOLEAN_VALUES.fetch(raw.to_s.strip.downcase) do
            raise InvalidRow, I18n.t('spree.redirection.import.errors.invalid_external_redirection',
                                     value: raw.to_s.strip)
          end
        end

        def created_by_name
          import.user.respond_to?(:full_name) ? import.user.full_name : import.user&.email
        end
      end
    end
  end
end
