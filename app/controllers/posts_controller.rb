class PostsController < ApplicationController
  before_action :require_admin
  before_action :set_post, only: %i[ show update ]

  def index
    posts = Post.all.order(id: :desc)
    @posts = set_pagination_for(posts, 30)
  end

  def show; end

  def update
    if @post.update(post_params)
      redirect_to post_path(@post.aid), notice: "更新しました"
    else
      flash.now[:alert] = "更新できませんでした"
      render :show, status: :unprocessable_entity
    end
  end

  private

  def post_params
    params.expect(
      post: [
        :visibility,
        :status
      ]
    )
  end

  def set_post
    @post = Post.find_by(aid: params[:aid])
  end
end
