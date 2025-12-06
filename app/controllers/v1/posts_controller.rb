class V1::PostsController < V1::ApplicationController
  before_action :require_signin, except: %i[ show quotes diffusions reactions ]

  def show
    @post = Post
      .from_normal_account
      .is_normal
      .is_opened
      .with_associations
      .find_by(aid: params[:aid])
    if @post
      if @post.replies.any?
        @replies = @post.replies
          .with_associations
          .order(id: :desc)
          .limit(50)
      end
      render template: 'v1/posts/show', formats: [:json]
    else
      render json: {
        status: 'error',
        message: '投稿が見つかりませんでした'
      }, status: :not_found
    end
  end

  def quotes
    @post = Post.find_by(aid: params[:post_aid])
    unless @post
      render json: { status: 'error', message: '投稿が見つかりません' }, status: :not_found
      return
    end

    @posts = @post.quotes
      .from_normal_account
      .is_normal
      .is_opened
      .with_associations
      .order(id: :desc)
      .limit(50)

    render template: 'v1/posts/index', formats: [:json]
  end

  def diffusions
    @post = Post.find_by(aid: params[:post_aid])
    unless @post
      render json: { status: 'error', message: '投稿が見つかりません' }, status: :not_found
      return
    end

    @accounts = @post.diffused_by
      .where(status: :normal)
      .includes(:icon)
      .order('diffuses.id DESC')
      .limit(50)

    render template: 'v1/accounts/index', formats: [:json]
  end

  def reactions
    @post = Post.find_by(aid: params[:post_aid])
    unless @post
      render json: { status: 'error', message: '投稿が見つかりません' }, status: :not_found
      return
    end

    @reactions = @post.reactions
      .joins(:account)
      .where(accounts: { status: :normal })
      .includes(account: :icon, emoji: :image)
      .order(id: :desc)

    if params[:emoji_aid]
      @reactions = @reactions.joins(:emoji).where(emojis: { aid: params[:emoji_aid] })
    end

    @reactions = @reactions.limit(50)

    # Get unique emojis used for tabs
    emoji_ids = @post.reactions.select(:emoji_id).distinct
    @emojis = Emoji.where(id: emoji_ids).includes(:image)

    render template: 'v1/posts/reactions', formats: [:json]
  end

  def create
    @post = Post.new
    @post.account = @current_account
    @post.assign_attributes(post_params)
    if @post.save
      # 通知の作成
      create_notifications

      render template: 'v1/posts/show', formats: [:json], status: :created
    else
      render json: {
        status: 'error',
        message: '投稿に失敗しました',
        error: @post.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    @post = @current_account.posts.find_by(aid: params[:aid])
    if @post.update(status: :deleted)
      render json: { status: 'success', message: '投稿を削除しました' }, status: :ok
    else
      render json: {
        status: 'error',
        message: '投稿の削除に失敗しました',
        errors: @post.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def create_notifications
    # リプライ
    if @post.reply.present?
      NotificationCreator.call(
        actor: @current_account,
        recipient: @post.reply.account,
        action: :reply,
        notifiable: @post
      )
    end

    # 引用
    if @post.quote.present?
      NotificationCreator.call(
        actor: @current_account,
        recipient: @post.quote.account,
        action: :quote,
        notifiable: @post
      )
    end

    # メンション
    mentions = @post.content.scan(/@([a-zA-Z0-9_]+)/).flatten.uniq
    if mentions.any?
      Account.where(name_id: mentions).find_each do |recipient|
        NotificationCreator.call(
          actor: @current_account,
          recipient: recipient,
          action: :mention,
          notifiable: @post
        )
      end
    end
  end

  def post_params
    params.expect(
      post: [
        :reply_aid,
        :quote_aid,
        :content,
        :visibility,
        media_files: [],
        drawing_attributes: [:data, :name, :description]
      ]
    )
  end
end
