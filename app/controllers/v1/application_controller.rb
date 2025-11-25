class V1::ApplicationController < ApplicationController
  # protect_from_forgery with: :null_session
  # before_action :require_signin

  private

  def require_signin
    return if @current_account

    render json: { status: 'error', message: 'サインインしてください' }, status: :unauthorized
  end
end
