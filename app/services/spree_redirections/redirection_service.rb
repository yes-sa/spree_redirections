# frozen_string_literal: true

module SpreeRedirections
  class RedirectionService
    class RedirectionServiceError < StandardError; end

    def initialize(old_url, query_string, server_name)
      @old_url = old_url
      @query_string = query_string
      @old_url_joined = [old_url, query_string].join('?').sub(%r{[/?\s]*$}, '').strip
      @store_url = Rails.env.development? ? ENV.fetch('SERVER_NAME_IMITATION', nil) : server_name
    end

    def call
      return if @store_url.blank? || @old_url.blank? || @old_url_joined.blank?
      return if redirect.blank?

      [redirect.http_status, { 'Location' => redirect.new_url }, [I18n.t('spree.redirection.redirecting')]]
    rescue StandardError => e
      raise RedirectionServiceError, e
    end

    def redirect
      return @redirect if defined?(@redirect)

      @redirect = SpreeRedirections::Redirection.find_by(old_url: @old_url_joined, store_url: @store_url)
    end
  end
end
