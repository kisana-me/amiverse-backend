class V1::AccountsController < V1::ApplicationController
  def show
    @account = Account
      .is_normal
      .is_opened
      .find_by(name_id: params[:name_id])
    if @account
      render template: "v1/accounts/show", formats: [ :json ]
    else
      render json: {
        status: "error",
        message: "アカウントが見つかりませんでした"
      }, status: :not_found
    end
  end

  def following
    return unless set_listed_account

    @accounts = @account.following
      .where(status: :normal)
      .includes(:icon)
      .order("follows.id DESC")
      .limit(50)

    render template: "v1/accounts/index", formats: [ :json ]
  end

  def followers
    return unless set_listed_account

    @accounts = @account.followers
      .where(status: :normal)
      .includes(:icon)
      .order("follows.id DESC")
      .limit(50)

    render template: "v1/accounts/index", formats: [ :json ]
  end

  private

  def set_listed_account
    @account = Account.is_normal.is_opened.find_by(aid: params[:account_aid])
    unless @account
      render json: { status: "error", message: "アカウントが見つかりません" }, status: :not_found
      return false
    end
    true
  end
end
