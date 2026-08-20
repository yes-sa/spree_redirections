# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::ImportSchemas::Redirections, type: :model do
  subject(:schema) { described_class.new }

  it 'defines the expected fields' do
    expect(schema.headers).to eq(%w[store_url old_url new_url http_status external_redirection])
  end

  it 'marks store_url, old_url, new_url and http_status as required' do
    expect(schema.required_fields).to match_array(%w[store_url old_url new_url http_status])
  end

  it 'marks external_redirection as optional' do
    expect(schema.optional_fields).to eq(%w[external_redirection])
  end

  it 'labels each field' do
    expect(schema.label_for_field('store_url')).to eq('Store URL')
  end
end
