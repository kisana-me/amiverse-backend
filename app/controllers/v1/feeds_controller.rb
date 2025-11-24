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
      .limit(500)

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

    post_ids = scores.sort_by { |id, score| [-score, -id] }.first(50).map(&:first)

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
        quote: [:account],
        reactions: [:emoji],
      )
      .where(id: post_ids)
      .in_order_of(:id, post_ids)
    render template: 'v1/posts/index', formats: [:json]
  end

  def follow
    following_ids = @current_account.following.ids

    posts = Post
      .where(account_id: following_ids)
      .is_normal
      .isnt_closed
      .order(created_at: :desc)
      .limit(50)

    diffuses = Diffuse
      .where(account_id: following_ids)
      .includes(:account)
      .joins(:account)
      .where(accounts: { status: :normal })
      .joins(:post)
      .where(posts: { status: :normal })
      .where.not(posts: { visibility: :closed })
      .order(created_at: :desc)
      .limit(50)

    mixed_items = (posts + diffuses).sort_by(&:created_at).reverse.first(50)

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
        quote: [:account],
        reactions: [:emoji],
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
          account_aid: item.account.aid,
          created_at: item.created_at
        }
      end
    end.compact
    render template: 'v1/feeds/current', formats: [:json]
  end

  def current
    posts = Post
      .from_normal_account
      .is_normal
      .is_opened
      .order(created_at: :desc)
      .limit(100)

    diffuses = Diffuse
      .includes(:account)
      .joins(:account)
      .where(accounts: { status: :normal })
      .joins(:post)
      .where(posts: { status: :normal, visibility: :opened })
      .order(created_at: :desc)
      .limit(100)

    mixed_items = (posts + diffuses).sort_by(&:created_at).reverse.first(100)

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
        quote: [:account],
        reactions: [:emoji],
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
          account_aid: item.account.aid,
          created_at: item.created_at
        }
      end
    end.compact
    render template: 'v1/feeds/current', formats: [:json]
  end

  private

  def post_params
    params.expect(
      post: [
        :content,
        :visibility
      ]
    )
  end
end
