class DiffusesController < ApplicationController
  before_action :require_signin
  before_action :set_post

  def create
    @diffuse = @current_account.diffuses.build(post: @post)
    if @diffuse.save
      redirect_to request.referer || post_path(@post.aid), notice: 'Post was successfully diffused.'
    else
      redirect_to request.referer || post_path(@post.aid), alert: 'Failed to diffuse the post.'
    end
  end

  def destroy
    @diffuse = @current_account.diffuses.find_by(post: @post)
    if @diffuse&.destroy
      redirect_to request.referer || post_path(@post.aid), notice: 'Diffuse was successfully removed.', status: :see_other
    else
      redirect_to request.referer || post_path(@post.aid), alert: 'Failed to remove diffuse.'
    end
  end

  private

  def set_post
    @post = Post.find_by(aid: params[:post_aid])
    render_404 unless @post
  end
end
