class V1::AccountsController < V1::ApplicationController
  def show
    @account = Account
      .is_normal
      .is_opened
      .find_by(name_id: params[:name_id])
    if @account
      render template: 'v1/accounts/show', formats: [:json]
    else
      render json: {
        status: 'error',
        message: 'アカウントが見つかりませんでした'
      }, status: :not_found
    end
  end
end
