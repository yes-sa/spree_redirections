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

  let(:redirection) { described_class.new(valid_attributes) }
  let(:spree_store_finder) { instance_double(Spree::Stores::FindCurrent) }
  let(:store) { create(:store, default: true) }
  let(:custom_domain) { create(:custom_domain, store: store, url: store.url) }

  before do
    custom_domain
    allow(Spree).to receive(:current_store_finder).and_return(spree_store_finder)
    allow(spree_store_finder).to receive(:execute).and_return(store)
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
        before do
          allow(spree_store_finder).to receive(:execute).and_return(nil)
        end

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
          redirection.new_url = 'not-a-url'

          expect(redirection).to be_valid
          expect(redirection.errors[:new_url]).to be_blank
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

    context 'not_admin_redirection validation' do
      let(:error_message) { I18n.t('spree.redirection.errors.redirection_to_admin') }

      context 'with correct urls' do
        it 'is valid' do
          expect(redirection).to be_valid
        end
      end

      context 'with old_url to admin site' do
        before { valid_attributes['old_url'] = '/something/admin/something' }

        it 'is invalid' do
          expect(redirection).not_to be_valid
          expect(redirection.errors[:base]).to include(error_message)
        end
      end

      context 'with new_url to admin site' do
        before { valid_attributes['new_url'] = 'www.example.com/something/admin/something' }

        it 'is invalid' do
          expect(redirection).not_to be_valid
          expect(redirection.errors[:base]).to include(error_message)
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
        before { valid_attributes['old_url'] = 'www.example.com/something/something' }

        it 'is invalid' do
          expect(redirection).not_to be_valid
          expect(redirection.errors[:old_url]).to include(error_message)
        end
      end

      context 'with invalid beggining' do
        before { valid_attributes['old_url'] = 'something/something' }

        it 'is invalid' do
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
      it 'returns both deleted and non-deleted records' do
        expect(described_class.with_archival)
          .to include(active_redirection, deleted_redirection)
      end

      it 'removes default ordering' do
        records = described_class.with_archival.to_a
        expect(records).to contain_exactly(active_redirection, deleted_redirection)
      end
    end
  end

  describe '#destroy (soft delete)' do
    let!(:persisted_redirection) do
      described_class.create!(valid_attributes)
    end

    it 'does not remove the record from the database' do
      expect {
        persisted_redirection.destroy
      }.not_to(change { described_class.with_archival.count })
    end

    it 'sets deleted_at timestamp' do
      freeze_time do
        now = Time.current

        persisted_redirection.destroy
        persisted_redirection.reload

        expect(persisted_redirection.deleted_at)
          .to be_within(1.second).of(now)
      end
    end

    it 'removes the record from the default scope' do
      persisted_redirection.destroy

      expect(described_class.all).not_to include(persisted_redirection)
      expect(described_class.with_archival).to include(persisted_redirection)
    end
  end

  describe 'ransackable_attributes' do
    it 'returns the allowed ransack attributes' do
      expect(described_class.ransackable_attributes).to match_array(
        %w[
          id old_url new_url http_status external_redirection
          created_at updated_at deleted_at
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
