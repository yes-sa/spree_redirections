# frozen_string_literal: true

module Spree
  module Admin
    class RedirectionsController < Spree::Admin::ResourceController
      before_action :set_created_by, only: [:create]

      def index
        @collection =
          if params.permit(:with_archival)[:with_archival].present?
            ::SpreeRedirections::Redirection.with_archival
          else
            ::SpreeRedirections::Redirection.all
          end
      end

      def create
        @redirection = ::SpreeRedirections::Redirection.new(permitted_resource_params)
        if @redirection.save
          redirect_to spree.admin_redirections_path, notice: I18n.t('spree.redirection.success')
        else
          render :new, status: :unprocessable_content
        end
      end

      def destroy
        @redirection = ::SpreeRedirections::Redirection.find(permitted_destroy_params[:id])
        if @redirection.present? && @redirection.destroy(current_user: try_spree_current_user.full_name)
          redirect_to spree.admin_redirections_path, notice: I18n.t('spree.redirection.success')
        else
          redirect_to spree.admin_redirections_path, alert: I18n.t('spree.redirection.errors.destroy_failed')
        end
      end

      private

      def permitted_resource_params
        params.require(:redirection).permit(
          :id, :store_url, :old_url, :new_url, :http_status, :external_redirection, :created_by
        )
      end

      def permitted_destroy_params
        params.permit(:id)
      end

      def set_created_by
        params[:redirection].merge!(created_by: try_spree_current_user.full_name)
      end

      protected

      def model_class
        SpreeRedirections::Redirection
      end
    end
  end
end
