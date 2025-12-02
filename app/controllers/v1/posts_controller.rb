class V1::PostsController < V1::ApplicationController
  before_action :require_signin, except: %i[ show ]

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

  def create
    @post = Post.new
    @post.account = @current_account
    @post.assign_attributes(post_params)
    if @post.save
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
