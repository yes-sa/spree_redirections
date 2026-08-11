# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Imports::RowProcessors::Redirection, type: :model do
  let(:store) { create(:store, default: true) }
  let(:custom_domain) { create(:custom_domain, store: store, url: 'www.example.com') }
  let(:import) { create(:redirection_import) }

  before do
    custom_domain
    %w[store_url old_url new_url http_status external_redirection].each do |field|
      import.mappings.create!(schema_field: field, file_column: field)
    end
  end

  def build_row(data)
    import.rows.create!(row_number: import.rows.count + 1, data: data.to_json, status: 'pending')
  end

  describe '#process!' do
    context 'with valid attributes' do
      let(:row) do
        build_row(
          'store_url' => 'www.example.com',
          'old_url' => '/old-path',
          'new_url' => '/new-path',
          'http_status' => '301',
          'external_redirection' => 'false'
        )
      end

      it 'creates a new redirection' do
        expect { described_class.new(row).process! }.to change(SpreeRedirections::Redirection, :count).by(1)
      end

      it 'assigns the attributes from the row' do
        redirection = described_class.new(row).process!

        expect(redirection).to be_persisted
        expect(redirection.store_url).to eq('www.example.com')
        expect(redirection.old_url).to eq('/old-path')
        expect(redirection.new_url).to eq('/new-path')
        expect(redirection.http_status).to eq('301')
        expect(redirection.external_redirection).to be(false)
        expect(redirection.created_by).to eq(import.user.full_name)
      end
    end

    context 'when a redirection with the same store_url/old_url already exists' do
      let!(:existing) do
        create(:redirection, store_url: 'www.example.com', old_url: '/old-path', new_url: '/stale', http_status: '301')
      end
      let(:row) do
        build_row(
          'store_url' => 'www.example.com',
          'old_url' => '/old-path',
          'new_url' => '/new-path',
          'http_status' => '302',
          'external_redirection' => 'false'
        )
      end

      it 'updates the existing redirection instead of creating a duplicate' do
        expect { described_class.new(row).process! }.not_to change(SpreeRedirections::Redirection, :count)

        existing.reload
        expect(existing.new_url).to eq('/new-path')
        expect(existing.http_status).to eq('302')
      end
    end

    context 'with invalid attributes' do
      let(:row) do
        build_row(
          'store_url' => 'www.example.com',
          'old_url' => '/old-path',
          'new_url' => '/new-path',
          'http_status' => 'not-a-status',
          'external_redirection' => 'false'
        )
      end

      it 'raises an error the caller can record as a row failure' do
        expect { described_class.new(row).process! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when store_url is missing' do
      let(:row) do
        build_row(
          'store_url' => '',
          'old_url' => '/old-path',
          'new_url' => '/new-path',
          'http_status' => '301',
          'external_redirection' => 'false'
        )
      end

      it 'raises an argument error' do
        expect { described_class.new(row).process! }.to raise_error(ArgumentError, 'Store URL is required')
      end
    end
  end
end
