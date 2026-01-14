# frozen_string_literal: true

module SpreeRedirections
  class RedirectionService
    class RedirectionServiceError < StandardError; end

    def initialize(old_url, query_string, server_name)
      @old_url = old_url
      @query_string = query_string
      @old_url_joined = [old_url, query_string].join('?').sub(%r{[/?\s]*$}, '').strip
      @store = Spree.current_store_finder.new(url: server_name).execute
    end

    def call
      return if @store.blank? || @old_url.blank? || @old_url_joined.blank?

      redirect = SpreeRedirections::Redirection.find_by(old_url: @old_url_joined, store_id: @store&.id)
      return if redirect.blank?

      [redirect.http_status, { 'Location' => redirect.new_url }, ['Redirecting...']]
    rescue StandardError => e
      raise RedirectionServiceError, e
    end
  end
end
