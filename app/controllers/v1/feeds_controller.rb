class V1::FeedsController < V1::ApplicationController
  before_action :require_signin, except: %i[ index current ]
  # index: おすすめ
  # follow: フォロー中
  # current: 最新順

  def index
    posts = Post
      .from_normal_account
      .is_normal
      .is_opened
      .order(id: :desc)
      .limit(50)

    post_ids_pool = posts.pluck(:id)

    replies_counts = Post.where(reply_id: post_ids_pool).group(:reply_id).count
    quotes_counts = Post.where(quote_id: post_ids_pool).group(:quote_id).count
    diffuses_counts = Diffuse.where(post_id: post_ids_pool).group(:post_id).count
    reactions_counts = Reaction.where(post_id: post_ids_pool).group(:post_id).count

    scores = post_ids_pool.map do |id|
      score = (replies_counts[id] || 0) * 3 +
              (quotes_counts[id] || 0) * 4 +
              (diffuses_counts[id] || 0) * 2 +
              (reactions_counts[id] || 0) * 1
      [id, score]
    end

    post_ids = scores.sort_by { |id, score| [-score, -id] }.first(30).map(&:first)

    @posts = Post
      .from_normal_account
      .is_normal
      .is_opened
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
      .where(id: post_ids)
      .in_order_of(:id, post_ids)
    render template: 'v1/posts/index', formats: [:json]
  end

  def follow
    cursor_time = params[:cursor].present? ? Time.at(params[:cursor].to_f) : Time.current
    following_ids = @current_account.following.is_normal.ids

    posts = Post
      .where(account_id: following_ids)
      .is_normal
      .isnt_closed
      .where('created_at < ?', cursor_time)
      .order(created_at: :desc)
      .limit(30)

    diffuses = Diffuse
      .where(account_id: following_ids)
      .includes(:account)
      .joins(:account)
      .where(accounts: { status: :normal })
      .joins(:post)
      .where(posts: { status: :normal })
      .where.not(posts: { visibility: :closed })
      .where('diffuses.created_at < ?', cursor_time)
      .order(created_at: :desc)
      .limit(30)

    mixed_items = (posts + diffuses).sort_by(&:created_at).reverse.first(30)

    if mixed_items.present?
      response.headers['X-Next-Cursor'] = mixed_items.last.created_at.to_f.to_s
    end

    post_ids = mixed_items.map { |item| item.is_a?(Post) ? item.id : item.post_id }.uniq

    @posts = Post
      .from_normal_account
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
      .where(id: post_ids)

    posts_by_id = @posts.index_by(&:id)

    @feeds = mixed_items.map do |item|
      if item.is_a?(Post)
        post = posts_by_id[item.id]
        next unless post

        {
          type: 'post',
          post_aid: post.aid
        }
      else
        post = posts_by_id[item.post_id]
        next unless post

        {
          type: 'diffuse',
          post_aid: post.aid,
          account: {
            aid: item.account.aid,
            name: item.account.name,
            name_id: item.account.name_id,
            icon_url: item.account.icon_url
          },
          created_at: item.created_at
        }
      end
    end.compact
    render template: 'v1/feeds/feed', formats: [:json]
  end

  def current
    current_cursor = params[:cursor].present? ? Time.at(params[:cursor].to_f) : Time.current

    sql = <<~SQL
      (
        SELECT 
          posts.id AS id, 
          'Post' AS type, 
          posts.created_at AS created_at
        FROM posts
        INNER JOIN accounts ON accounts.id = posts.account_id
        WHERE accounts.status = 0
          AND posts.status = 0
          AND posts.visibility = 0
          AND posts.created_at < :cursor
      )
      UNION ALL
      (
        SELECT 
          diffuses.id AS id, 
          'Diffuse' AS type, 
          diffuses.created_at AS created_at
        FROM diffuses
        INNER JOIN accounts ON accounts.id = diffuses.account_id
        INNER JOIN posts ON posts.id = diffuses.post_id
        WHERE accounts.status = 0
          AND posts.status = 0
          AND posts.visibility = 0
          AND diffuses.created_at < :cursor
      )
      ORDER BY created_at DESC
      LIMIT 30
    SQL

    sanitized_sql = Post.sanitize_sql_array([sql, cursor: current_cursor])
    results = Post.connection.select_all(sanitized_sql).to_a

    if results.present?
      response.headers['X-Next-Cursor'] = results.last['created_at'].to_time.to_f.to_s
    end

    post_ids = []
    diffuse_ids = []

    results.each do |row|
      if row['type'] == 'Post'
        post_ids << row['id']
      else
        diffuse_ids << row['id']
      end
    end

    diffuses_by_id = Diffuse.where(id: diffuse_ids).includes(:account).index_by(&:id)
    
    diffuse_post_ids = diffuses_by_id.values.map(&:post_id)
    all_post_ids = (post_ids + diffuse_post_ids).uniq

    @posts = Post
      .from_normal_account
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
      .where(id: all_post_ids)

    posts_by_id = @posts.index_by(&:id)

    @feeds = results.map do |row|
      if row['type'] == 'Post'
        post = posts_by_id[row['id']]
        next unless post

        {
          type: 'post',
          post_aid: post.aid
        }
      else
        diffuse = diffuses_by_id[row['id']]
        next unless diffuse
        
        post = posts_by_id[diffuse.post_id]
        next unless post

        {
          type: 'diffuse',
          post_aid: post.aid,
          account: {
            aid: diffuse.account.aid,
            name: diffuse.account.name,
            name_id: diffuse.account.name_id,
            icon_url: diffuse.account.icon_url
          },
          created_at: diffuse.created_at
        }
      end
    end.compact
    render template: 'v1/feeds/feed', formats: [:json]
  end

  def account
    @account = Account.find_by(aid: params[:aid])
    if @account.nil? || !@account.normal?
      render json: { error: 'Account not found' }, status: :not_found
      return
    end

    cursor_time = params[:cursor].present? ? Time.at(params[:cursor].to_f) : Time.current

    posts = Post
      .where(account_id: @account.id)
      .is_normal
      .isnt_closed
      .where('created_at < ?', cursor_time)
      .order(created_at: :desc)
      .limit(30)

    diffuses = Diffuse
      .where(account_id: @account.id)
      .includes(:account)
      .joins(:account)
      .where(accounts: { status: :normal })
      .joins(:post)
      .where(posts: { status: :normal })
      .where.not(posts: { visibility: :closed })
      .where('diffuses.created_at < ?', cursor_time)
      .order(created_at: :desc)
      .limit(30)

    mixed_items = (posts + diffuses).sort_by(&:created_at).reverse.first(30)

    if mixed_items.present?
      response.headers['X-Next-Cursor'] = mixed_items.last.created_at.to_f.to_s
    end

    post_ids = mixed_items.map { |item| item.is_a?(Post) ? item.id : item.post_id }.uniq

    @posts = Post
      .from_normal_account
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
      .where(id: post_ids)

    posts_by_id = @posts.index_by(&:id)

    @feeds = mixed_items.map do |item|
      if item.is_a?(Post)
        post = posts_by_id[item.id]
        next unless post

        {
          type: 'post',
          post_aid: post.aid
        }
      else
        post = posts_by_id[item.post_id]
        next unless post

        {
          type: 'diffuse',
          post_aid: post.aid,
          account: {
            aid: item.account.aid,
            name: item.account.name,
            name_id: item.account.name_id,
            icon_url: item.account.icon_url
          },
          created_at: item.created_at
        }
      end
    end.compact
    render template: 'v1/feeds/feed', formats: [:json]
  end
end
