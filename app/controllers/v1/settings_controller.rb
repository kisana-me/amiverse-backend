class V1::SettingsController < V1::ApplicationController
  before_action :require_signin
  before_action :set_account, only: %i[ account ]

  def account
    if @account.update(account_params)
      render json: {
        status: 'success',
        message: '更新しました',
        account: JSON.parse(render_to_string(partial: 'v1/accounts/current_account', locals: { account: @account }, formats: :json))
      }, status: :ok
    else
      render json: {
        status: 'error',
        message: '更新できませんでした',
        errors: @account.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def notification
    setting = @current_account.notification_setting
    render json: {
      status: 'success',
      setting: setting
    }, status: :ok
  end

  def update_notification
    setting = @current_account.notification_setting
    if setting.update(notification_params)
      render json: {
        status: 'success',
        message: '更新しました',
        setting: setting
      }, status: :ok
    else
      render json: {
        status: 'error',
        message: '更新できませんでした',
        errors: setting.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def leave
    if @current_account.update(status: :deleted)
      sign_out
      render json: { status: 'success', message: '退会しました' }, status: :ok
    else
      render json: {
        status: 'error',
        message: '退会できませんでした',
        errors: @current_account.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_account
    @account = Account.find_by(aid: @current_account.aid)
  end

  def account_params
    params.expect(
      account: [
        :name,
        :name_id,
        :description,
        :birthdate,
        :visibility,
        # password
        # password_confirmation
        :icon_file,
        :banner_file
      ]
    )
  end

  def notification_params
    params.expect(
      setting: [
        :reaction, :diffuse, :reply, :quote, :follow, :mention,
        :wp_reaction, :wp_diffuse, :wp_reply, :wp_quote, :wp_follow, :wp_mention
      ]
    )
  end
end
