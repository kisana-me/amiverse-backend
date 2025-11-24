class V1::SettingsController < V1::ApplicationController
  before_action :require_signin
  before_action :set_account, only: %i[icon post_account]

  def icon
    images = Image
      .is_normal
      .is_opened
      .where(account: @current_account)
      .order(id: :desc)
    @images = set_pagination_for(images)
  end

  def post_account
    if @account.update(account_params)
      render json: { status: 'success' }, status: :ok

    else
      render json: {
        status: 'error',
        message: '更新できませんでした',
        errors: @account.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def leave
    @current_account.update(status: :deleted)
    sign_out
    redirect_to root_url, notice: "ご利用いただきありがとうございました"
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
        # icon_aid
        :icon_file,
      ]
    )
  end
end
