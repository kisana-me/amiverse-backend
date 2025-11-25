class V1::ReactionsController < V1::ApplicationController
  before_action :require_signin
  before_action :set_post

  # POST /v1/posts/:aid/reaction
  def create
    emoji = Emoji.is_normal.find_by(aid: params[:emoji_aid])
    return render_error('絵文字が見つかりません', :not_found) unless emoji

    reaction = @post.reactions.find_or_initialize_by(account: @current_account)
    reaction.emoji = emoji

    if reaction.save
      render json: {
        status: 'success',
        message: 'リアクションしました',
        data: { emoji_aid: emoji.aid, post_aid: @post.aid }
      }, status: :ok
    else
      render_error('リアクションの保存に失敗しました', :unprocessable_entity, reaction.errors.full_messages)
    end
  end

  # DELETE /v1/posts/:aid/reaction
  def destroy
    reaction = @post.reactions.find_by(account: @current_account)
    return render_error('リアクションが見つかりません', :not_found) unless reaction

    if reaction.destroy
      render json: { status: 'success', message: 'リアクションを削除しました' }, status: :ok
    else
      render_error('リアクションの削除に失敗しました', :unprocessable_entity, reaction.errors.full_messages)
    end
  end

  private

  def set_post
    @post = Post.from_normal_account.is_normal.find_by(aid: params[:post_aid])
    render_error('投稿が見つかりません', :not_found) unless @post
  end

  def render_error(message, status, errors = nil)
    payload = { status: 'error', message: message }
    payload[:errors] = errors if errors
    render json: payload, status: status
  end
end
