# frozen_string_literal: true

module Spree
  module Admin
    class RedirectionsController < Spree::Admin::ResourceController
      private

      def permitted_resource_params
        params.require(:redirection).permit(:id, :store_url, :old_url, :new_url, :http_status, :external_redirection)
      end

      protected

      def model_class
        SpreeRedirections::Redirection
      end
    end
  end
end
