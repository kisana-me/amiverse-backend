class V1::FollowsController < V1::ApplicationController
  before_action :require_signin
  before_action :set_account

  # POST /v1/accounts/:account_aid/follow
  def create
    return render_error('自分自身をフォローすることはできません', :unprocessable_entity) if @account == @current_account

    follow = @current_account.active_relationships.find_or_initialize_by(followed: @account)

    if @account.remote? && @current_account.activity_pub_profile.present?
      follow.activity_id ||= @current_account.activity_pub_profile.uri + '/follows/' + SecureRandom.base36(14)
    end

    if follow.save
      NotificationCreator.call(
        actor: @current_account,
        recipient: @account,
        action: :follow,
        notifiable: follow
      )

      # ActivityPub Delivery
      if @account.activity_pub_instance.present? && @current_account.activity_pub_profile.present?
        activity = ActivityPub::Serializer::Follow.new(follow).to_json
        ActivityPub::DeliveryJob.perform_later(
          @current_account.id,
          @account.activity_pub_profile.inbox_url,
          activity
        )
      end

      render json: {
        status: 'success',
        message: 'フォローしました',
        data: { account_aid: @account.aid }
      }, status: :ok
    else
      render_error('フォローの保存に失敗しました', :unprocessable_entity, follow.errors.full_messages)
    end
  end

  # DELETE /v1/accounts/:account_aid/follow
  def destroy
    follow = @current_account.active_relationships.find_by(followed: @account)
    return render_error('フォローしていません', :not_found) unless follow

    # ActivityPub Delivery (Undo Follow)
    if @account.activity_pub_instance.present? && @current_account.activity_pub_profile.present?
      undo_activity = ActivityPub::Serializer::Undo.new(follow).to_json

      ActivityPub::DeliveryJob.perform_later(
        @current_account.id,
        @account.activity_pub_profile.inbox_url,
        undo_activity
      )
    end

    if follow.destroy
      render json: { status: 'success', message: 'フォローを解除しました' }, status: :ok
    else
      render_error('フォロー解除に失敗しました', :unprocessable_entity, follow.errors.full_messages)
    end
  end

  private

  def set_account
    @account = Account.is_normal.find_by(aid: params[:account_aid])
    render_error('アカウントが見つかりません', :not_found) unless @account
  end

  def render_error(message, status, errors = nil)
    payload = { status: 'error', message: message }
    payload[:errors] = errors if errors
    render json: payload, status: status
  end
end
