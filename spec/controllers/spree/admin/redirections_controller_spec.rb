# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Admin::RedirectionsController, type: :controller do
  routes { Spree::Core::Engine.routes }
  stub_authorization!

  describe '#model_class' do
    it 'returns SpreeRedirections::Redirection' do
      expect(controller.send(:model_class))
        .to eq(SpreeRedirections::Redirection)
    end
  end

  describe '#permitted_resource_params' do
    let(:params_hash) do
      {
        redirection: {
          store_url: 'example.com',
          old_url: '/old',
          new_url: 'https://example.com',
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

    it 'permits only the expected attributes' do
      permitted = controller.send(:permitted_resource_params)

      expect(permitted.to_h).to eq(
        'store_url' => 'example.com',
        'old_url' => '/old',
        'new_url' => 'https://example.com',
        'http_status' => 301,
        'external_redirection' => true
      )
    end

    it 'raises ParameterMissing when :redirection is not present' do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new({})
      )

      expect {
        controller.send(:permitted_resource_params)
      }.to raise_error(ActionController::ParameterMissing, /redirection/)
    end
  end

  describe '#create' do
    let!(:admin_user) { create(:admin_user) }
    let(:store) { create(:store, default: true, url: 'example.com') }
    let(:custom_domain) { create(:custom_domain, store: store, url: store.url) }

    let(:valid_params) do
      {
        redirection: {
          store_url: 'example.com',
          old_url: '/old',
          new_url: 'https://example.com',
          http_status: 301,
          external_redirection: false
        }
      }
    end

    before do
      custom_domain
      # Make Spree think we are logged in as an admin.
      allow(controller).to receive(:try_spree_current_user).and_return(admin_user) if controller.respond_to?(:try_spree_current_user)

      # Bypass authorization layers that may still run in before_actions.
      allow(controller).to receive_messages(spree_current_user: admin_user, authorize_admin: true, spree_authorize!: true, authorize!: true)
    end

    context 'with valid parameters' do
      before do
        post :create, params: valid_params
      end

      it 'creates a new redirection' do
        created = SpreeRedirections::Redirection.with_archival.order(:created_at).last

        expect(created).to be_present
        expect(created.store_url).to eq('example.com')
        expect(created.old_url).to eq('/old')
        expect(created.new_url).to eq('https://example.com')
        expect(created.http_status.to_s).to eq('301')
        expect(created.external_redirection).to be(false)
      end

      it 'sets a success flash message' do
        expect(flash[:notice]).to eq(I18n.t('spree.redirection.success'))
      end

      it 'redirects to index' do
        expect(response).to redirect_to(spree.admin_redirections_path)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          redirection: valid_params[:redirection].merge(new_url: nil)
        }
      end

      it 'does not create a redirection' do
        expect {
          post :create, params: invalid_params
        }.not_to change(SpreeRedirections::Redirection.with_archival, :count)
      end

      it 'renders :new with unprocessable_content' do
        post :create, params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:new)
      end
    end
  end
end
