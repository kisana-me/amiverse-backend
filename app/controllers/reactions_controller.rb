class ReactionsController < ApplicationController
  before_action :require_signin
  before_action :require_admin

  def react
    @emoji = Emoji.find_by(aid: params.expect(:emoji_aid))
    @post = Post.find_by(aid: params.expect(:post_aid))
    return render_404 unless @emoji && @post

    @reaction = Reaction.find_or_initialize_by(
      account: @current_account,
      post: @post
    )
    if @reaction.emoji == @emoji
      @reaction.destroy!
      redirect_to post_path(@post.aid), notice: 'Reaction was successfully removed.'
      return
    end
    @reaction.emoji = @emoji

    if @reaction.save
      redirect_to post_path(@post.aid), notice: 'Reaction was successfully added.'
    else
      flash.now[:alert] = 'Failed to add the reaction.'
      render 'posts/show', status: :unprocessable_entity
    end
  end
end
