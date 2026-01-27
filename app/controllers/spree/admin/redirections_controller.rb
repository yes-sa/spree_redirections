# frozen_string_literal: true

module Spree
  module Admin
    class RedirectionsController < Spree::Admin::ResourceController
      def create
        @redirection = ::SpreeRedirections::Redirection.new(permitted_resource_params)

        if @redirection.save
          redirect_to spree.admin_redirections_path, notice: I18n.t('spree.redirection.success')
        else
          render :new, status: :unprocessable_content
        end
      end

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
