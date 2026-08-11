# frozen_string_literal: true

module Spree
  module Imports
    class Redirections < Spree::Import
      def row_processor_class
        Spree::Imports::RowProcessors::Redirection
      end

      def model_class
        SpreeRedirections::Redirection
      end

      def self.model_class
        SpreeRedirections::Redirection
      end
    end
  end
end
