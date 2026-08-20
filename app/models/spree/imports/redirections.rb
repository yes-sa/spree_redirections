# frozen_string_literal: true

module Spree
  module Imports
    class Redirections < Spree::Import
      CANDIDATE_DELIMITERS = [',', ';', "\t", '|'].freeze

      def row_processor_class
        Spree::Imports::RowProcessors::Redirection
      end

      def model_class
        SpreeRedirections::Redirection
      end

      def self.model_class
        SpreeRedirections::Redirection
      end

      # The delimiter the admin picked, corrected when it demonstrably does not fit the
      # file. Getting this wrong is silent and baffling: the whole line parses as one
      # column, nothing auto-maps, and every row fails with "store_url is required"
      # rather than anything mentioning delimiters. A spreadsheet exported in a Polish
      # locale is semicolon-separated while the dropdown defaults to a comma, so this is
      # the normal case, not an edge case.
      #
      # Only steps in when the declared delimiter yields a single column *and* another
      # candidate yields more, so a correctly declared file is never second-guessed.
      def preferred_delimiter
        @preferred_delimiter ||= begin
          # spree_admin builds the dropdown with options_for_select([',', ';', '|', '\t'])
          # -- single-quoted, so its tab option submits a literal backslash-t (two
          # characters) rather than a tab and never matches anything. Translate it back.
          raw = super
          declared = raw == '\t' ? "\t" : raw

          detect_delimiter(declared) || declared
        end
      end

      # Where the "import finished" button should send the user. spree_admin's loader
      # partial and wizard layout hardcode the dashboard; our overrides (app/view_overrides)
      # prefer these when the import type defines them, and fall back to the dashboard
      # when it doesn't -- so products/customers imports keep Spree's stock behaviour.
      def admin_results_path
        Spree::Core::Engine.routes.url_helpers.admin_redirections_path
      end

      def admin_results_label
        I18n.t('spree.redirection.import.back_to_redirections')
      end

      private

      def detect_delimiter(declared)
        header = attachment_file_content.to_s.lines.first
        return if header.blank?
        return if column_count(header, declared) > 1

        best = CANDIDATE_DELIMITERS.max_by { |candidate| column_count(header, candidate) }
        best if column_count(header, best) > 1
      end

      def column_count(header, delimiter)
        # Deliberately not blank?: a tab is whitespace, so "\t".blank? is true and the
        # tab candidate would be discarded before it was ever tried.
        return 0 if delimiter.nil? || delimiter.empty? # rubocop:disable Rails/Blank

        ::CSV.parse_line(header, col_sep: delimiter)&.size.to_i
      rescue ::CSV::MalformedCSVError
        0
      end
    end
  end
end
