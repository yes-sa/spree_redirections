# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SpreeRedirections::Redirection, type: :model do
  let(:valid_attributes) do
    {
      store_url: 'www.example.com',
      old_url: '/old',
      new_url: '/new',
      http_status: '301',
      external_redirection: false
    }
  end

  let(:redirection) { create(:redirection, **valid_attributes) }
  let(:store) { create(:store, default: true) }
  let(:custom_domain) { create(:custom_domain, store: store, url: store.url) }

  before do
    custom_domain
  end

  describe '#prefixed_id' do
    it 'returns a Stripe-style prefixed id' do
      expect(redirection.prefixed_id).to match(/\Aredir_\w+\z/)
    end
  end

  describe '#to_param' do
    it 'stays the plain numeric id, since routes/controller look up by numeric id' do
      expect(redirection.to_param).to eq(redirection.id.to_s)
    end
  end

  describe 'validations' do
    context 'with valid attributes' do
      it 'is valid' do
        expect(redirection).to be_valid
      end
    end

    context 'presence validations' do
      %i[store_url old_url new_url http_status].each do |attribute|
        it "is invalid without #{attribute}" do
          redirection[attribute] = nil

          expect(redirection).not_to be_valid
          expect(redirection.errors[attribute]).to be_present
        end
      end
    end

    context 'old_url uniqueness validation' do
      context 'with unique store_url/old_url pair' do
        let(:another_redirection) { create(:redirection, store_url: store.url, old_url: "#{redirection.old_url}/different") }

        it 'is valid' do
          expect(another_redirection).to be_valid
        end
      end

      context 'with duplicated store_url/old_url pair' do
        let(:duplicate_redirection) { create(:redirection, store_url: store.url) }

        it 'is not valid' do
          duplicate_redirection.old_url = redirection.old_url
          expect(duplicate_redirection).not_to be_valid
          expect(duplicate_redirection.errors[:old_url])
            .to include(I18n.t('spree.redirection.errors.uniqueness_for_store_url'))
        end
      end
    end

    context 'http_status validation' do
      context 'with allowed values' do
        %w[301 302 303].each do |status|
          it "accepts #{status}" do
            redirection.http_status = status
            expect(redirection).to be_valid
          end
        end
      end

      context 'with disallowed values' do
        %w[200 307 308 404 foo].each do |status|
          it "rejects #{status}" do
            redirection.http_status = status

            expect(redirection).not_to be_valid
            expect(redirection.errors[:http_status])
              .to include(I18n.t('spree.errors.invalid_http_status'))
          end
        end
      end
    end

    context 'existing_store validation' do
      context 'with correct store_url' do
        it 'is valid' do
          expect(redirection).to be_valid
        end
      end

      context 'with not existing store_url' do
        it 'is not valid' do
          redirection.store_url = 'not_exists'

          expect(redirection).not_to be_valid
          expect(redirection.errors[:store_url])
            .to include(I18n.t('spree.errors.store_not_found'))
        end
      end
    end

    context 'external_new_url_format validation' do
      let(:error_message) { I18n.t('spree.redirection.errors.invalid_url') }

      context 'when new_url is blank' do
        it 'does not add errors from external_new_url_format (returns early)' do
          redirection.external_redirection = true
          redirection.new_url = ''

          expect(redirection).not_to be_valid
          expect(redirection.errors[:new_url]).to be_present
          expect(redirection.errors[:new_url]).not_to include(error_message)
        end
      end

      context 'when external_redirection is false' do
        it 'does not validate the external url format' do
          redirection.external_redirection = false
          redirection.new_url = '/still-relative'

          expect(redirection).to be_valid
          expect(redirection.errors[:new_url]).to be_blank
        end

        it 'leaves a non-relative target to internal_new_url_format' do
          redirection.external_redirection = false
          redirection.new_url = 'not-a-url'

          expect(redirection).not_to be_valid
          expect(redirection.errors[:new_url]).not_to include(error_message)
          expect(redirection.errors[:new_url])
            .to include(I18n.t('spree.redirection.errors.relative_new_url'))
        end
      end

      context 'when external_redirection is true' do
        before { redirection.external_redirection = true }

        context 'in development environment' do
          before { allow(Rails.env).to receive(:development?).and_return(true) }

          it 'is valid when new_url starts with http://www' do
            redirection.new_url = 'http://www.example.com/path'

            expect(redirection).to be_valid
          end

          it 'is valid when new_url starts with https://www' do
            redirection.new_url = 'https://www.example.com/path'

            expect(redirection).to be_valid
          end

          it 'is invalid when new_url does not start with http://www or https://www' do
            redirection.new_url = 'https://example.com/path'

            expect(redirection).not_to be_valid
            expect(redirection.errors[:new_url]).to include(error_message)
          end
        end

        context 'in non-development environment' do
          before { allow(Rails.env).to receive(:development?).and_return(false) }

          it 'is valid when new_url starts with https://www' do
            redirection.new_url = 'https://www.example.com/path'

            expect(redirection).to be_valid
          end

          it 'is invalid when new_url starts with http://www' do
            redirection.new_url = 'http://www.example.com/path'

            expect(redirection).not_to be_valid
            expect(redirection.errors[:new_url]).to include(error_message)
          end

          it 'is invalid when new_url does not start with https://www' do
            redirection.new_url = 'https://example.com/path'

            expect(redirection).not_to be_valid
            expect(redirection.errors[:new_url]).to include(error_message)
          end
        end
      end
    end

    context 'internal_new_url_format validation' do
      let(:error_message) { I18n.t('spree.redirection.errors.relative_new_url') }

      context 'when external_redirection is false' do
        before { redirection.external_redirection = false }

        it 'is valid with a rooted relative path' do
          redirection.new_url = '/products/rings'

          expect(redirection).to be_valid
        end

        it 'is valid with a bare slash' do
          redirection.new_url = '/'

          expect(redirection).to be_valid
        end

        it 'is invalid with an absolute https url' do
          redirection.new_url = 'https://www.example.com/path'

          expect(redirection).not_to be_valid
          expect(redirection.errors[:new_url]).to include(error_message)
        end

        it 'is invalid with a host-only url' do
          redirection.new_url = 'www.example.com/path'

          expect(redirection).not_to be_valid
          expect(redirection.errors[:new_url]).to include(error_message)
        end

        it 'is invalid with a protocol-relative url' do
          redirection.new_url = '//evil.example.com'

          expect(redirection).not_to be_valid
          expect(redirection.errors[:new_url]).to include(error_message)
        end
      end

      context 'when external_redirection is true' do
        before { redirection.external_redirection = true }

        it 'does not require a relative path' do
          redirection.new_url = 'https://www.example.com/path'

          expect(redirection).to be_valid
          expect(redirection.errors[:new_url]).to be_blank
        end
      end

      context 'when new_url is blank' do
        it 'leaves the complaint to the presence validation' do
          redirection.external_redirection = false
          redirection.new_url = ''

          expect(redirection).not_to be_valid
          expect(redirection.errors[:new_url]).to be_present
          expect(redirection.errors[:new_url]).not_to include(error_message)
        end
      end
    end

    context 'not_admin_redirection validation' do
      let(:error_message) { I18n.t('spree.redirection.errors.redirection_to_admin') }

      context 'with correct urls' do
        it 'is valid' do
          expect(redirection).to be_valid
        end
      end

      context 'with old_url to admin site' do
        it 'is invalid' do
          redirection.old_url = '/something/admin/something'

          expect(redirection).not_to be_valid
          expect(redirection.errors[:old_url]).to include(error_message)
        end
      end

      context 'with new_url to admin site' do
        it 'is invalid' do
          redirection.new_url = 'www.example.com/something/admin/something'
          expect(redirection).not_to be_valid
          expect(redirection.errors[:new_url]).to include(error_message)
        end
      end
    end

    context 'old_url format validation' do
      let(:error_message) { I18n.t('spree.redirection.errors.relative_old_url') }

      context 'with correct old_url format' do
        it 'is valid' do
          expect(redirection).to be_valid
        end
      end

      context 'with external site old_url' do
        it 'is invalid' do
          redirection.old_url = 'www.example.com/something/something'
          expect(redirection).not_to be_valid
          expect(redirection.errors[:old_url]).to include(error_message)
        end
      end

      context 'with invalid beggining' do
        it 'is invalid' do
          redirection.old_url = 'something/something'
          expect(redirection).not_to be_valid
          expect(redirection.errors[:old_url]).to include(error_message)
        end
      end
    end
  end

  describe 'scopes' do
    let!(:active_redirection) do
      described_class.create!(valid_attributes.merge(old_url: '/active'))
    end

    let!(:deleted_redirection) do
      described_class.create!(
        valid_attributes.merge(
          old_url: '/deleted',
          deleted_at: Time.current
        )
      )
    end

    describe 'default_scope' do
      it 'returns only non-deleted records' do
        expect(described_class.all).to include(active_redirection)
        expect(described_class.all).not_to include(deleted_redirection)
      end

      it 'orders records by created_at desc' do
        newer = described_class.create!(
          valid_attributes.merge(old_url: '/newer')
        )

        expect(described_class.all.to_a).to eq([newer, active_redirection])
      end
    end

    describe '.with_archival' do
      it 'returns only removed records' do
        records = described_class.with_archival.to_a
        expect(records).to contain_exactly(deleted_redirection)
      end
    end
  end

  describe '#destroy (soft delete)' do
    let!(:persisted_redirection) do
      described_class.create!(valid_attributes)
    end
    let(:user_full_name) { 'John Doe' }

    context 'when soft deleted' do
      it 'does not remove the record from the database' do
        expect {
          persisted_redirection.destroy(current_user: user_full_name)
        }.to(change { described_class.with_archival.count })
      end

      it 'sets deleted_at timestamp' do
        freeze_time do
          persisted_redirection.destroy(current_user: user_full_name)
          persisted_redirection.reload

          expect(persisted_redirection.deleted_at)
            .to eq(Time.current)
        end
      end

      it 'removes the record from the default scope' do
        persisted_redirection.destroy(current_user: user_full_name)

        expect(described_class.all).not_to include(persisted_redirection)
        expect(described_class.with_archival).to include(persisted_redirection)
      end
    end

    context 'when soft delete is not successful' do
      before do
        allow(persisted_redirection).to receive(:update).and_return(false)
      end

      it 'does not set deleted_at when the update fails' do
        persisted_redirection.destroy(current_user: user_full_name)
        persisted_redirection.reload

        expect(persisted_redirection.deleted_at).to be_nil
      end
    end
  end

  describe 'ransackable_attributes' do
    it 'returns the allowed ransack attributes' do
      expect(described_class.ransackable_attributes).to match_array(
        %w[
          id old_url new_url http_status external_redirection
          created_at created_by updated_at deleted_at deleted_by
        ]
      )
    end

    it 'does not depend on the auth object argument' do
      expect(described_class.ransackable_attributes(nil))
        .to match_array(described_class.ransackable_attributes)

      expect(described_class.ransackable_attributes(['auth']))
        .to match_array(described_class.ransackable_attributes)
    end
  end
end
