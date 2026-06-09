# frozen_string_literal: true

module SpreeRedirections
  class RedirectionService
    class RedirectionServiceError < StandardError; end

    def initialize(old_url, query_string = '', server_name = nil)
      @old_url = old_url
      @query_string = query_string
      @old_url_joined = [old_url, query_string].join('?').sub(%r{[/?\s]*$}, '').strip
      @store_url = ENV.fetch('FRONT_URL', nil) || server_name
    end

    def call
      return if @store_url.blank? || @old_url.blank? || @old_url_joined.blank?

      redirection = redirect
      return if redirection.blank?

      [redirection.http_status, { 'Location' => redirection.new_url }, [I18n.t('spree.redirection.redirecting')]]
    rescue StandardError => e
      raise RedirectionServiceError, e
    end

    def redirect
      SpreeRedirections::Redirection.find_by_sql([
                                                   recursive_redirection_search,
                                                   {
                                                     old_url: @old_url_joined,
                                                     store_url: @store_url
                                                   }
                                                 ]).first
    end

    def recursive_redirection_search
      table_name = SpreeRedirections::Redirection.table_name

      <<~SQL.squish
        WITH RECURSIVE redirect_chain AS (
          SELECT
            #{table_name}.*,
            1 AS depth,
            ARRAY[#{table_name}.id] AS visited_ids
          FROM #{table_name}
          WHERE #{table_name}.old_url = :old_url
            AND #{table_name}.store_url = :store_url

          UNION ALL

          SELECT
            next_redirections.*,
            redirect_chain.depth + 1 AS depth,
            redirect_chain.visited_ids || next_redirections.id AS visited_ids
          FROM #{table_name} next_redirections
          INNER JOIN redirect_chain
            ON next_redirections.old_url = redirect_chain.new_url
           AND next_redirections.store_url = :store_url
          WHERE NOT next_redirections.id = ANY(redirect_chain.visited_ids)
        )
        SELECT *
        FROM redirect_chain
        ORDER BY depth DESC
        LIMIT 1
      SQL
    end
  end
end
