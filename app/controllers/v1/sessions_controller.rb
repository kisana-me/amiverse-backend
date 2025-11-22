class V1::SessionsController < V1::ApplicationController
  def signout
    if sign_out
      render json: { status: 'success', message: 'サインアウトしました' }
    else
      render json: { status: 'error', message: 'サインアウトできませんでした' }
    end
  end
end
