# frozen_string_literal: true

require 'rails_helper'
require 'rack/mock'
require Rails.root.join('../../lib/middleware/spree_redirections/redirections_middleware')

RSpec.describe RedirectionsMiddleware do
  subject(:middleware) { described_class.new(app) }

  let(:path) { '/nieistnieje' }
  let(:query_string) { 'asd=2' }
  let(:server_name) { 'localhost' }

  let(:env) do
    Rack::MockRequest.env_for("http://#{server_name}#{path}?#{query_string}").merge(
      'PATH_INFO' => path,
      'QUERY_STRING' => query_string,
      'SERVER_NAME' => server_name
    )
  end

  let(:status) { 200 }
  let(:headers) { { 'Content-Type' => 'text/html' } }
  let(:body) { ['OK'] }

  let(:app) { ->(_env) { [status, headers, body] } }

  let(:service_instance) { instance_double(SpreeRedirections::RedirectionService) }
  let(:service_result) { nil }

  before do
    stub_const('RedirectionServiceError', Class.new(StandardError))
    stub_const('Sentry', Class.new)
    allow(Sentry).to receive(:capture_exception)
    allow(SpreeRedirections::RedirectionService).to receive(:new)
      .with(path, query_string, server_name)
      .and_return(service_instance)
    allow(service_instance).to receive(:call).and_return(service_result)
  end

  describe '#call' do
    context 'when app returns non-404' do
      let(:status) { 200 }

      it 'passes through the response' do
        expect(middleware.call(env)).to eq([status, headers, body])
      end

      it 'does not call the redirection service' do
        middleware.call(env)
        expect(SpreeRedirections::RedirectionService).not_to have_received(:new)
      end

      it 'does not capture anything in Sentry' do
        middleware.call(env)
        expect(Sentry).not_to have_received(:capture_exception)
      end
    end

    context 'when app returns 404' do
      let(:status) { 404 }

      context 'and service returns a redirect' do
        let(:service_result) { ['301', { 'Location' => '/new' }, ['Redirecting...']] }

        it 'returns the redirect tuple' do
          expect(middleware.call(env)).to eq(service_result)
        end

        it 'does not capture anything in Sentry' do
          middleware.call(env)
          expect(Sentry).not_to have_received(:capture_exception)
        end

        it 'calls RedirectionService with env values' do
          middleware.call(env)
          expect(SpreeRedirections::RedirectionService).to have_received(:new)
            .with(path, query_string, server_name)
          expect(service_instance).to have_received(:call)
        end
      end

      context 'and service returns nil' do
        let(:service_result) { nil }

        it 'returns the original 404 response' do
          expect(middleware.call(env)).to eq([404, headers, body])
        end

        it 'does not capture anything in Sentry' do
          middleware.call(env)
          expect(Sentry).not_to have_received(:capture_exception)
        end
      end

      context 'and service raises an error' do
        before do
          allow(service_instance).to receive(:call).and_raise(StandardError, 'service call failed')
        end

        it 'captures the exception and re-raises' do
          expect { middleware.call(env) }.to raise_error(StandardError, /service call failed/)

          expect(Sentry).to have_received(:capture_exception).with(
            instance_of(RedirectionServiceError),
            hash_including(
              level: 'error',
              tags: { component: 'middleware', category: 'redirections' }
            )
          )
        end
      end
    end

    context 'when app raises a routing error' do
      let(:routing_error) { StandardError.new('routing failed') }
      let(:app) { ->(_env) { raise routing_error } }

      context 'and service returns a redirect' do
        let(:service_result) { ['302', { 'Location' => 'https://example.com' }, ['Redirecting...']] }

        it 'returns redirect and does not re-raise' do
          expect(middleware.call(env)).to eq(service_result)
        end

        it 'does not capture anything in Sentry' do
          middleware.call(env)
          expect(Sentry).not_to have_received(:capture_exception)
        end
      end

      context 'and service returns nil' do
        let(:service_result) { nil }

        it 'captures the routing error and re-raises it' do
          expect { middleware.call(env) }.to raise_error(StandardError, /routing failed/)

          expect(Sentry).to have_received(:capture_exception).with(
            instance_of(RedirectionServiceError),
            hash_including(
              level: 'error',
              tags: { component: 'middleware', category: 'redirections' }
            )
          )
        end
      end
    end

    context 'when RedirectionService initialization raises' do
      let(:status) { 404 }

      before do
        allow(SpreeRedirections::RedirectionService).to receive(:new)
          .and_raise(StandardError, 'service init failed')
      end

      it 'captures and re-raises' do
        expect { middleware.call(env) }.to raise_error(StandardError, /service init failed/)

        expect(Sentry).to have_received(:capture_exception).with(
          instance_of(RedirectionServiceError),
          hash_including(
            level: 'error',
            tags: { component: 'middleware', category: 'redirections' }
          )
        )
      end
    end
  end

  describe '#capture_message' do
    let(:exception) { StandardError.new('boom') }
    let(:env) { { 'SERVER_NAME' => 'verona.pl', 'QUERY_STRING' => 'example.com?arg=value' } }

    it 'sends exception to Sentry wrapped in RedirectionServiceError' do
      middleware.capture_message(exception, env)

      expect(Sentry).to have_received(:capture_exception).with(
        instance_of(RedirectionServiceError),
        hash_including(
          level: 'error',
          tags: { component: 'middleware', category: 'redirections' },
          extra: hash_including(url: 'example.com?arg=value', server_name: 'verona.pl')
        )
      )
    end
  end
end
