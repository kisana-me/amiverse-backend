class V1::SearchController < V1::ApplicationController
  def index
    query = params[:query]
    cursor = params[:cursor]&.to_i
    limit = 20

    filter = [
      "status = 'normal'",
      "visibility = 'opened'",
      "account_status = 'normal'"
    ]

    if cursor.present?
      cursor_time = Time.at(cursor).utc.iso8601
      filter << "created_at < '#{cursor_time}'"
    end

    search_options = {
      limit: limit,
      sort: ['created_at:desc'],
      filter: filter.join(' AND '),
      attributes_to_highlight: ['content']
    }

    results = Post.index.search(query, search_options)
    ids = results['hits'].map { |h| h['id'] }

    @posts = Post.where(id: ids)
                  .includes(
                    :account,
                    :diffuses,
                    :reply,
                    :replies,
                    :quotes,
                    :images,
                    :videos,
                    quote: [:account],
                    reactions: [:emoji],
                    account: [:icon],
                  )
                  .order(created_at: :desc)

    if @posts.present?
      response.headers['X-Next-Cursor'] = @posts.last.created_at.to_f.to_s
    end

    render template: 'v1/feeds/feed_only_posts', formats: [:json]
  end
end
