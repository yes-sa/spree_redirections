# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Importing redirections from a CSV', type: :model do
  let(:store) { create(:store, default: true) }
  let(:custom_domain) { create(:custom_domain, store: store, url: 'www.example.com') }
  let(:import) { create(:redirection_import) }

  # Runs the whole pipeline (mapping -> row creation -> processing) in-process against
  # an arbitrary CSV body, the way the admin wizard does.
  def import_csv(csv, delimiter: ',')
    create(:redirection_import).tap do |i|
      i.attachment.attach(io: StringIO.new(csv), filename: 'redirections.csv', content_type: 'text/csv')
      i.preferred_inline = true
      i.preferred_delimiter = delimiter
      i.save!
      i.start_mapping!
      i.complete_mapping!
      i.reload
    end
  end

  it 'creates a redirection for every row in the file' do
    custom_domain
    import.preferred_inline = true
    import.save!

    import.start_mapping!
    import.complete_mapping!
    import.reload

    expect(import).to be_complete
    expect(import.rows.completed.count).to eq(2)
    expect(import.rows.failed.count).to eq(0)

    internal = SpreeRedirections::Redirection.find_by(old_url: '/old-1')
    expect(internal.new_url).to eq('/new-1')
    expect(internal.http_status).to eq('301')
    expect(internal.external_redirection).to be(false)

    external = SpreeRedirections::Redirection.find_by(old_url: '/old-2')
    expect(external.new_url).to eq('https://www.external-example.com/new-2')
    expect(external.http_status).to eq('302')
    expect(external.external_redirection).to be(true)
  end

  context 'when the columns are in a different order than the schema' do
    # Mapping matches CSV headers to schema fields by name, so column order in the file
    # is irrelevant -- pinning that here because a reordered export is the normal case
    # when the file comes back out of a spreadsheet.
    let(:csv) do
      <<~CSV
        old_url,external_redirection,store_url,http_status,new_url
        /old-1,fałsz,www.example.com,301,/new-1
        /old-2,prawda,www.example.com,302,https://www.external-example.com/new-2
      CSV
    end

    it 'still imports every row' do
      custom_domain
      import = import_csv(csv)

      expect(import.rows.failed.map(&:validation_errors)).to be_empty
      expect(import).to be_complete
      expect(import.rows.completed.count).to eq(2)

      expect(SpreeRedirections::Redirection.find_by(old_url: '/old-1'))
        .to have_attributes(new_url: '/new-1', http_status: '301', external_redirection: false)
      expect(SpreeRedirections::Redirection.find_by(old_url: '/old-2'))
        .to have_attributes(http_status: '302', external_redirection: true)
    end
  end

  context 'when the file does not use the delimiter the admin picked' do
    # A spreadsheet exported in a Polish locale is semicolon-separated while the upload
    # form defaults to a comma. Left uncorrected the whole line is one column, nothing
    # auto-maps, and every row fails with "store_url is required" -- a message that says
    # nothing about delimiters, which makes this near-impossible to diagnose from the UI.
    def csv_with(separator)
      [
        %w[old_url new_url external_redirection http_status store_url],
        ['/old-1', '/new-1', 'FAŁSZ', '301', 'www.example.com'],
        ['/old-2', 'https://www.external-example.com/x', 'PRAWDA', '302', 'www.example.com']
      ].map { |row| row.join(separator) }.join("\n").concat("\n")
    end

    [';', "\t", '|'].each do |separator|
      it "detects #{separator.inspect} and still imports every row" do
        custom_domain
        import = import_csv(csv_with(separator), delimiter: ',')

        expect(import.preferred_delimiter).to eq(separator)
        expect(import.mappings.mapped.count).to eq(5)
        expect(import.rows.completed.count).to eq(2)
        expect(import.rows.failed).to be_empty
      end
    end

    it "reads spree_admin's literal '\\t' dropdown value as a real tab" do
      # spree_admin builds the dropdown with single-quoted '\t', so picking "tab" submits
      # two characters (backslash, t) rather than a tab character.
      custom_domain
      import = import_csv(csv_with("\t"), delimiter: '\t')

      expect(import.preferred_delimiter).to eq("\t")
      expect(import.rows.completed.count).to eq(2)
    end

    it 'does not second-guess a delimiter that already parses' do
      custom_domain
      import = import_csv(csv_with(','), delimiter: ',')

      expect(import.preferred_delimiter).to eq(',')
      expect(import.rows.completed.count).to eq(2)
    end
  end
end
