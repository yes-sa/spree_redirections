class Spree::Admin::RedirectionsController < ::Spree::Admin::ResourceController

  private

  protected def model_class
    SpreeRedirections::Redirection
  end

  def permitted_resource_params
    debugger
    params.require(:redirection).permit(:store_url, :old_url, :new_url ,:http_status ,:external_redirection)
  end
end