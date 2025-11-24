class V1::PostsController < V1::ApplicationController
  def index
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
      .order(id: :desc)
      .limit(500)
    render template: 'v1/posts/index', formats: [:json]
  end

  def show
    @post = Post
      .from_normal_account
      .is_normal
      .is_opened
      .includes(
        :account,
        :diffuses,
        :images,
        reply: [:account],
        quote: [:account],
        replies: [:account],
        quotes: [:account],
        reactions: [:emoji],
      )
      .find_by(aid: params[:aid])
    if @post
      if @post.replies.any?
        @replies = @post.replies
          .from_normal_account
          .is_normal
          .is_opened
          .includes(
            :account,
            :diffuses,
            :reply,
            :replies,
            :quotes,
            quote: [:account],
            reactions: [:emoji],
          )
        .order(id: :desc)
        .limit(500)
      end
      render template: 'v1/posts/show', formats: [:json]
    else
      render json: { error: 'Post not found' }, status: :not_found
    end
  end

  def create
    @post = Post.new(post_params)
    @post.account = @current_account
    if @post.save
      render template: 'v1/posts/show', formats: [:json], status: :created
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @post = Post.find_by(aid: params[:aid])
    @post.update(post_params)
    if @post.save
      render template: 'v1/posts/show', formats: [:json]
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @post = Post.find_by(aid: params[:aid])
    if @post.update(visibility: :deleted)
      render json: { status: 'success' }
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def post_params
    params.expect(
      post: [
        :reply_aid,
        :quote_aid,
        :content,
        :visibility,
        media_files: []
      ]
    )
  end
end
