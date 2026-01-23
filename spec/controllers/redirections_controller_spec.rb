# frozen_string_literal: true
require "rails_helper"

RSpec.describe Spree::Admin::RedirectionsController, type: :controller do
  routes { Spree::Core::Engine.routes }

  describe "#model_class" do
    it "returns SpreeRedirections::Redirection" do
      expect(controller.send(:model_class))
        .to eq(SpreeRedirections::Redirection)
    end
  end

  describe "#permitted_resource_params" do
    let(:params_hash) do
      {
        redirection: {
          store_url: "https://example.com",
          old_url: "/old",
          new_url: "/new",
          http_status: 301,
          external_redirection: true,

          # should be filtered out
          deleted_at: Time.current,
          admin: true
        }
      }
    end

    before do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new(params_hash)
      )
    end

    it "permits only the expected attributes" do
      permitted = controller.send(:permitted_resource_params)

      expect(permitted.to_h).to eq(
                                  "store_url" => "https://example.com",
                                  "old_url" => "/old",
                                  "new_url" => "/new",
                                  "http_status" => 301,
                                  "external_redirection" => true
                                )
    end


    it "raises ParameterMissing when :redirection is not present" do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new({})
      )

      expect {
        controller.send(:permitted_resource_params)
      }.to raise_error(ActionController::ParameterMissing, /redirection/)
    end
  end
end
