# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SpreeRedirections::Redirection, type: :model do
  let(:valid_attributes) do
    {
      store_url: 'store_url',
      old_url: '/old',
      new_url: '/new',
      http_status: '301',
      external_redirection: false
    }
  end

  let(:redirection) { described_class.new(valid_attributes) }
  let(:spree_store_finder) { instance_double(Spree::Stores::FindCurrent) }
  let(:store) { create(:store, default: true) }

  before do
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
            expect(redirection.errors[:base])
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
          expect(redirection.errors[:base])
            .to include(I18n.t('spree.errors.store_not_found'))
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
end
