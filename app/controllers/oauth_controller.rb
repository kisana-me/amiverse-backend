class OauthController < ApplicationController
  # OAuth Controller Ver. 1.1.0

  include OauthManagement

  before_action :require_signin, only: %i[fetch]

  def start
    provider = (params[:provider] || "anyur").to_sym
    state = SecureRandom.base36(24)
    oauth_authorize_url = generate_authorize_url(state, provider)

    session[:oauth_provider] = provider
    session[:oauth_state] = state

    redirect_to oauth_authorize_url, allow_other_host: true
  end

  def callback
    provider = session.delete(:oauth_provider).to_sym
    state = session.delete(:oauth_state)

    if params[:state] != state
      render plain: "Invalid state parameter", status: :unauthorized
      return
    end

    token_data = exchange_code_for_token(params[:code], provider)
    return if performed?

    resources = fetch_resources(token_data["access_token"], provider)
    return if performed?

    handle_oauth(token_data, resources, provider)
  end

  def fetch
    provider = (params[:provider] || "anyur").to_sym
    oauth_account = @current_account.oauth_accounts.find_by(provider: provider)

    unless oauth_account
      redirect_to settings_account_path, alert: "未連携の外部サービスです"
      return
    end

    if oauth_account.expires_at <= Time.current
      token_data = use_refresh_token(oauth_account.refresh_token, provider)
      return if performed?

      oauth_account.update!(
        access_token: token_data["access_token"],
        refresh_token: token_data["refresh_token"],
        expires_at: Time.current + token_data["expires_in"].to_i,
        fetched_at: Time.current
      )
    end

    resources = fetch_resources(oauth_account.access_token, provider)
    return if performed?

    update_subscription_info(provider, @current_account, resources)
    redirect_to settings_account_path, notice: "情報を更新しました!"
  end

  private

  # ========== #
  # 以下自由 / handle_oauth(token_data, resources, provider)で受け取る
  # ========== #

  def handle_oauth(token_data, resources, provider)
    uid = resources.dig("data", "persona_aid")
    oauth_account = OauthAccount.find_by(provider: provider, uid: uid)
    account = oauth_account&.account

    if @current_account && @current_account == account
      # 既に連携済みのアカウントが現在のアカウントと同じ場合、情報を更新
      oauth_account.assign_attributes(
        access_token: token_data["access_token"],
        refresh_token: token_data["refresh_token"],
        expires_at: Time.current + token_data["expires_in"].to_i,
        fetched_at: Time.current
      )
      oauth_account.save!
      update_subscription_info(provider, account, resources)
      redirect_to settings_account_path, notice: "情報を更新しました"
    elsif @current_account && account
      # 既に連携済みのアカウントが現在のアカウントと異なる場合、エラー
      redirect_to settings_account_path, alert: "既に他の本サービスアカウントと連携済みです"
    elsif @current_account && !account
      # 連携済みのアカウントが存在せず、現在のアカウントがサインイン中の場合、連携を追加
      if @current_account.oauth_accounts.where(provider: provider).any?
        redirect_to settings_account_path, alert: "既に同じ外部サービスのアカウントと連携済みです"
        return
      end
      OauthAccount.create!(
        account: @current_account,
        provider: provider,
        uid: uid,
        access_token: token_data["access_token"],
        refresh_token: token_data["refresh_token"],
        expires_at: Time.current + token_data["expires_in"].to_i,
        fetched_at: Time.current
      )
      update_subscription_info(provider, @current_account, resources)
      redirect_to settings_account_path, notice: "連携が完了しました"
    elsif !@current_account && account
      # 既に連携済みのアカウントが存在し、現在のアカウントが未サインインの場合、サインイン
      account.oauth_accounts.find_by(provider: provider, uid: uid).update(
        access_token: token_data["access_token"],
        refresh_token: token_data["refresh_token"],
        expires_at: Time.current + token_data["expires_in"].to_i,
        fetched_at: Time.current
      )
      update_subscription_info(provider, account, resources)
      sign_in(account)
      redirect_back_or root_path, notice: "サインインしました"
    elsif !@current_account && !account
      # 連携済みのアカウントが存在せず、現在のアカウントが未サインインの場合、新規登録へ
      session[:oauth_signup] = {
        provider: provider,
        uid: uid,
        access_token: token_data["access_token"],
        refresh_token: token_data["refresh_token"],
        expires_at: Time.current + token_data["expires_in"].to_i,
        fetched_at: Time.current,
        name: resources.dig("data", "name") || "",
        name_id: resources.dig("data", "name_id") || "",
        description: resources.dig("data", "description") || "",
        subscription: resources.dig("data", "subscription") || { "status" => "none", "plan" => "basic" }
      }
      redirect_to signup_path
    else
      # その他（通常は発生しない）
      redirect_to root_path, alert: "サインインエラー"
    end
  end

  def update_subscription_info(provider, account, resources)
    return unless provider == "anyur".to_sym

    account.meta["subscription"] = resources.dig("data", "subscription")
    account.save!
  end
end
