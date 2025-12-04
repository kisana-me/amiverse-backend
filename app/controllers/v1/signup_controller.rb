class V1::SignupController < V1::ApplicationController
  before_action :require_signout
  before_action :ensure_oauth_context

  def create
    @account = Account.new(account_params)
    @account.meta['subscription'] = session[:oauth_signup]['subscription']

    if @account.save
      sign_in(@account)
      NotificationCreator.call(
        actor: nil,
        recipient: @account,
        action: :signin
      )
      OauthAccount.create!(
        account: @account,
        provider: session[:oauth_signup]['provider'],
        uid: session[:oauth_signup]['uid'],
        access_token: session[:oauth_signup]['access_token'],
        refresh_token: session[:oauth_signup]['refresh_token'],
        expires_at: session[:oauth_signup]['expires_at'],
        fetched_at: session[:oauth_signup]['fetched_at']
      )
      session.delete(:oauth_signup)
      render json: { status: 'success', message: '登録完了' }, status: :created
    else
      render json: { status: 'error', message: '登録に失敗しました', errors: @account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def ensure_oauth_context
    unless session[:oauth_signup].present?

      render json: { status: 'error', message: '不正なアクセス' }, status: :forbidden
    end
  end

  def account_params
    params.expect(
      account: %i[
        name
        name_id
        description
        birthdate
        visibility
        password
        password_confirmation
      ]
    )
  end
end
