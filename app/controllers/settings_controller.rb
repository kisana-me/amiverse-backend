class SettingsController < ApplicationController
  before_action :require_signin
  before_action :set_account, only: %i[account icon post_account]

  def index; end

  def account; end

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
      redirect_to settings_account_path, notice: '更新しました'
    else
      flash.now[:alert] = '更新できませんでした'
      render :account
    end
  end

  def leave
    @current_account.update(status: :deleted)
    sign_out
    redirect_to root_url, notice: 'ご利用いただきありがとうございました'
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
        :icon_file
      ]
    )
  end
end
