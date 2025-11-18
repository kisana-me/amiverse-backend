class PostsController < ApplicationController
  before_action :require_signin, except: %i[ index show ]
  before_action :set_post, only: %i[ show ]
  before_action :set_correct_post, only: %i[ edit update destroy ]

  def index
    @posts = Post.all
  end

  def show
  end

  def new
    @post = Post.new
  end

  def edit
  end

  def create
    @post = Post.new(post_params)
    @post.account = @current_account
    if @post.save
      redirect_to post_path(@post.aid), notice: 'Post was successfully created.'
    else
      flash.now[:alert] = 'Failed to create the post.'
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @post.update(post_params)
      redirect_to post_path(@post.aid), notice: 'Post was successfully updated.', status: :see_other
    else
      flash.now[:alert] = 'Failed to update the post.'
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @post.update(status: :deleted)
      redirect_to post_path(@post.aid), notice: 'Post was successfully deleted.', status: :see_other
    else
      flash.now[:alert] = 'Failed to delete the post.'
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_post
    @post = Post
      .from_normal_account
      .find_by(aid: params.expect(:aid))
    return render_404 unless @post

    return if @post.normal? && @post.opened?

    if @current_account
      return if @post.account_id == @current_account.id
      return if admin?
    end
    render_404
  end

  def set_correct_post
    @post = Post
      .isnt_deleted
      .find_by(aid: params.expect(:aid), account: @current_account)
    render_404 unless @post
  end

  def post_params
    params.expect(
      post: [
        :reply_aid,
        :quote_aid,
        :content,
        :visibility
      ]
    )
  end
end
