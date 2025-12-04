class V1::DiffusesController < V1::ApplicationController
  before_action :require_signin
  before_action :set_post

  # POST /v1/posts/:post_aid/diffuse
  def create
    diffuse = @post.diffuses.find_or_initialize_by(account: @current_account)

    if diffuse.save
      NotificationCreator.call(
        actor: @current_account,
        recipient: @post.account,
        action: :diffuse,
        notifiable: @post
      )

      render json: {
        status: 'success',
        message: '拡散しました',
        data: { post_aid: @post.aid }
      }, status: :ok
    else
      render_error('拡散の保存に失敗しました', :unprocessable_entity, diffuse.errors.full_messages)
    end
  end

  # DELETE /v1/posts/:post_aid/diffuse
  def destroy
    diffuse = @post.diffuses.find_by(account: @current_account)
    return render_error('拡散が見つかりません', :not_found) unless diffuse

    if diffuse.destroy
      render json: { status: 'success', message: '拡散を削除しました' }, status: :ok
    else
      render_error('拡散の削除に失敗しました', :unprocessable_entity, diffuse.errors.full_messages)
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
