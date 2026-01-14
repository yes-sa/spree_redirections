# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SpreeRedirections::RedirectionService, type: :service do
  subject(:service_call) { described_class.new(old_url, query_string, server_name).call }

  let(:old_url) { '/nieistnieje' }
  let(:query_string) { 'asd=2' }
  let(:server_name) { 'localhost' }

  let(:store) { instance_double(Spree::Store, id: store_id) }
  let(:store_id) { 'store_1' }
  let(:store_finder) { instance_double('StoreFinder') }

  before do
    allow(Spree).to receive(:current_store_finder).and_return(store_finder)
    allow(store_finder).to receive(:new).with(url: server_name).and_return(store_finder)
    allow(store_finder).to receive(:execute).and_return(store)
  end

  describe '#call' do
    context 'when store is blank' do
      let(:store) { nil }

      it 'returns nil' do
        expect(service_call).to be_nil
      end
    end

    context 'when old_url is blank' do
      let(:old_url) { '' }

      it 'returns nil' do
        expect(service_call).to be_nil
      end
    end

    context 'when old_url_joined becomes blank (e.g. whitespace)' do
      let(:old_url) { '   ' }

      it 'returns nil' do
        expect(service_call).to be_nil
      end
    end

    context 'when no redirection exists' do
      before do
        allow(SpreeRedirections::Redirection).to receive(:find_by).and_return(nil)
      end

      it 'looks up by joined old_url + query_string and store_id and returns nil' do
        expect(SpreeRedirections::Redirection).to receive(:find_by).with(
          old_url: '/nieistnieje?asd=2',
          store_id: store_id
        )

        expect(service_call).to be_nil
      end
    end

    context 'when redirection exists' do
      let(:redirect) do
        instance_double(
          SpreeRedirections::Redirection,
          http_status: '301',
          new_url: 'https://example.com/new'
        )
      end

      before do
        allow(SpreeRedirections::Redirection).to receive(:find_by).and_return(redirect)
      end

      it 'returns rack-style redirect tuple' do
        expect(service_call).to eq(
          ['301', { 'Location' => 'https://example.com/new' }, ['Redirecting...']]
        )
      end

      it 'queries by joined url and store_id' do
        expect(SpreeRedirections::Redirection).to receive(:find_by).with(
          old_url: '/nieistnieje?asd=2',
          store_id: store_id
        )

        service_call
      end
    end

    context 'when query_string is blank' do
      let(:query_string) { '' }

      before do
        allow(SpreeRedirections::Redirection).to receive(:find_by).and_return(nil)
      end

      it "joins with '?' then strips trailing '?' so it searches just the path" do
        expect(SpreeRedirections::Redirection).to receive(:find_by).with(
          old_url: '/nieistnieje',
          store_id: store_id
        )

        service_call
      end
    end

    context 'when old_url or query_string have trailing slashes/spaces' do
      let(:old_url) { '/nieistnieje/ ' }
      let(:query_string) { 'asd=2 ' }

      before do
        allow(SpreeRedirections::Redirection).to receive(:find_by).and_return(nil)
      end

      it 'normalizes by trimming whitespace and removing trailing / ? spaces' do
        expect(SpreeRedirections::Redirection).to receive(:find_by).with(
          old_url: '/nieistnieje/ ?asd=2'.sub(%r{[/?\s]*$}, '').strip, # not super readable
          store_id: store_id
        )

        expected = [old_url, query_string].join('?').sub(%r{[/?\s]*$}, '').strip
        expect(expected).to eq('/nieistnieje/ ?asd=2'.strip.sub(%r{[/?\s]*$}, '')) # sanity

        service_call
      end
    end

    context 'when an error happens inside #call' do
      before do
        allow(SpreeRedirections::Redirection).to receive(:find_by).and_raise(StandardError, 'boom')
      end

      it 'wraps it in RedirectionServiceError' do
        expect { service_call }
          .to raise_error(described_class::RedirectionServiceError)
      end

      it 'preserves the original error message in the raised error' do
        expect { service_call }
          .to raise_error(described_class::RedirectionServiceError, /boom/)
      end
    end
  end

  describe 'initialization' do
    it 'uses Spree.current_store_finder with server_name to resolve store' do
      described_class.new(old_url, query_string, server_name)

      expect(Spree).to have_received(:current_store_finder)
      expect(store_finder).to have_received(:new).with(url: server_name)
      expect(store_finder).to have_received(:execute)
    end
  end
end
