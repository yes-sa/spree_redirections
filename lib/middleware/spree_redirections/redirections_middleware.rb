# frozen_string_literal: true

class RedirectionsMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      status, headers, body = @app.call(env)
    rescue StandardError => e
      routing_error = e
      status = 404
      headers = {}
      body = []
    end

    if routing_error.present? || status == 404
      redirection = SpreeRedirections::RedirectionService.new(*service_params(env).values).call
      return redirection if redirection.present?
    end
    raise routing_error if routing_error.present?

    [status, headers, body]
  rescue StandardError => e
    capture_message(e)
    raise
  end

  def capture_message(err)
    Sentry.capture_exception(RedirectionServiceError.new(err&.full_message),
                             level: 'error',
                             tags: { component: 'middleware', category: 'redirections' },
                             extra: { url: @old_url_joined, store: @store&.id })
  end

  private

  def service_params(env)
    {
      old_url: env['PATH_INFO'],
      old_url_params: env['QUERY_STRING'],
      server_name: env['SERVER_NAME']
    }
  end
end
