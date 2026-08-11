# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Importing redirections from a CSV', type: :model do
  let(:store) { create(:store, default: true) }
  let(:custom_domain) { create(:custom_domain, store: store, url: 'www.example.com') }
  let(:import) { create(:redirection_import) }

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
end
