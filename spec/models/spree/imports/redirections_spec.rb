# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Imports::Redirections, type: :model do
  it 'is registered as an available import type' do
    expect(Spree::Import.available_types).to include(described_class)
  end

  describe '#row_processor_class' do
    it 'returns the redirection row processor' do
      expect(described_class.new.row_processor_class).to eq(Spree::Imports::RowProcessors::Redirection)
    end
  end

  describe '#import_schema' do
    it 'resolves to the redirections schema' do
      expect(described_class.new.import_schema).to be_a(Spree::ImportSchemas::Redirections)
    end
  end

  describe '#model_class' do
    it 'returns SpreeRedirections::Redirection' do
      expect(described_class.new.model_class).to eq(SpreeRedirections::Redirection)
    end
  end

  describe '.model_class' do
    it 'returns SpreeRedirections::Redirection' do
      expect(described_class.model_class).to eq(SpreeRedirections::Redirection)
    end
  end

  describe '#group_column' do
    it 'is nil, so rows are processed independently' do
      expect(described_class.new.group_column).to be_nil
    end
  end
end
