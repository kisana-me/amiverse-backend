class V1::SessionsController < V1::ApplicationController
  def create
    unless @current_account
      return render json: { status: 'error', message: 'サインインしてください' }, status: :unauthorized
    end

    db_session = Session.new(account: @current_account)
    access_token = db_session.generate_token(SessionManagement::TOKEN_EXPIRES_IN)

    if db_session.save
      NotificationCreator.call(
        actor: nil,
        recipient: @current_account,
        action: :signin
      )
      render json: {
        status: 'success',
        access_token: access_token,
        expires_in: SessionManagement::TOKEN_EXPIRES_IN.to_i
      }
    else
      render json: { status: 'error', message: 'トークンを発行できませんでした' }, status: :unprocessable_entity
    end
  end

  def signout
    if sign_out
      render json: { status: 'success', message: 'サインアウトしました' }
    else
      render json: { status: 'error', message: 'サインアウトできませんでした' }
    end
  end
end
