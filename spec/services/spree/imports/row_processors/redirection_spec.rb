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
        expect { described_class.new(row).process! }
          .to raise_error(described_class::InvalidRow, /#{Regexp.escape(I18n.t('spree.errors.invalid_http_status'))}/)
      end

      it 'reports the failure entirely in the active locale' do
        # Regression: `validates ... message: I18n.t(...)` froze those two messages to the
        # boot locale, so a failed row mixed English and Polish in one message.
        row_pl = build_row(
          'store_url' => 'www.example.com',
          'old_url' => 'not-a-relative-path',
          'new_url' => '/new-path',
          'http_status' => 'not-a-status',
          'external_redirection' => 'false'
        )

        message = I18n.with_locale(:pl) do
          described_class.new(row_pl).process!
        rescue described_class::InvalidRow => e
          e.message
        end

        expect(message).to include(I18n.t('spree.redirection.errors.relative_old_url', locale: :pl))
        expect(message).to include(I18n.t('spree.errors.invalid_http_status', locale: :pl))
        expect(message).not_to include(I18n.t('spree.redirection.errors.relative_old_url', locale: :en))
      end
    end

    context 'with the external_redirection column' do
      # An external redirection is only valid with an https://www. target, so the
      # new_url has to match the boolean the row is expected to cast to.
      def process_with(external_redirection, new_url: '/new-path')
        row = build_row(
          'store_url' => 'www.example.com',
          'old_url' => "/old-#{SecureRandom.hex(4)}",
          'new_url' => new_url,
          'http_status' => '301',
          'external_redirection' => external_redirection
        )
        described_class.new(row).process!
      end

      {
        'prawda' => true, 'Prawda' => true, 'PRAWDA' => true, ' prawda ' => true,
        'tak' => true, 'Tak' => true, 'true' => true, 'yes' => true, '1' => true,
        'fałsz' => false, 'Fałsz' => false, 'FAŁSZ' => false, 'falsz' => false,
        'nie' => false, 'Nie' => false, 'false' => false, 'no' => false, '0' => false
      }.each do |raw, expected|
        it "casts #{raw.inspect} to #{expected}" do
          new_url = expected ? 'https://www.external-example.com/target' : '/new-path'

          expect(process_with(raw, new_url: new_url).external_redirection).to be(expected)
        end
      end

      it 'falls back to the column default when the value is blank' do
        expect(process_with('').external_redirection).to be(false)
      end

      it 'fails the row on an unrecognised value rather than silently importing false' do
        expect { process_with('moze') }
          .to raise_error(described_class::InvalidRow,
                          I18n.t('spree.redirection.import.errors.invalid_external_redirection', value: 'moze'))
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

      it 'raises a localized row error' do
        expect { described_class.new(row).process! }
          .to raise_error(described_class::InvalidRow, I18n.t('spree.redirection.import.errors.store_url_missing'))
      end
    end
  end
end
