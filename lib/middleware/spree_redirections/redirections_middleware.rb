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

    if (routing_error.present? || status == 404)
      old_url = env["PATH_INFO"]
      old_url_params = env["QUERY_STRING"]
      server_name = env['SERVER_NAME']
      redirection = SpreeRedirections::RedirectionService.new(old_url, old_url_params, server_name).call

      if redirection.present?
        return redirection
      end
    end

    raise routing_error if routing_error.present?

    [ status, headers, body ]
  rescue StandardError => e
    capture_message(e)
    raise
  end

  def capture_message(e)
    Sentry.capture_exception(RedirectionServiceError.new(e&.full_message),
                             level: 'error',
                             tags: { component: 'middleware', category: 'redirections' },
                             extra: { url: @old_url_joined, store: @store&.id })
  end
end
