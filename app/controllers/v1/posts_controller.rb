class V1::PostsController < V1::ApplicationController
  def index
    @posts = Post
      .from_normal_account
      .is_normal
      .is_opened
      .includes(
        :account,
        :reply,
        :replies,
        :quotes,
        quote: [:account],
      )
    render template: "v1/posts/index", formats: [:json]
  end

  def show
    @post = Post
      .from_normal_account
      .is_normal
      .is_opened
      .includes(
        :account,
        reply: [:account],
        quote: [:account],
        replies: [:account],
        quotes: [:account]
      )
      .find_by(aid: params[:aid])
    if @post
      render template: "v1/posts/show", formats: [:json]
    else
      render json: { error: "Post not found" }, status: :not_found
    end
  end

  def create
    @post = Post.new(post_params)
    if @post.save
      render template: "v1/posts/show", formats: [:json], status: :created
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @post = Post.find_by(aid: params[:aid])
    @post.update(post_params)
    if @post.save
      render template: "v1/posts/show", formats: [:json]
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy               
    @post = Post.find_by(aid: params[:aid])
    if @post.update(visibility: :deleted)
      render json: { status: "success" }
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
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
