class V1::SessionsController < V1::ApplicationController
  include OauthManagement

  # POST /v1/sessions/create
  # params { code: "code", code_verifier: "code_verifier", redirect_uri: "redirect_uri" }
  # returns { status: "success", access_token: "token", expires_in: 3600 }
  def create
    # ANYURにリクエスト
    provider = :anyur
    raise "Unsupported OAuth provider: #{provider}" unless OauthManagement::OAUTH_PROVIDERS.key?(provider)

    code = params[:code].to_s
    code_verifier = params[:code_verifier].to_s
    redirect_uri = params[:redirect_uri].to_s
    unless code && code_verifier && redirect_uri
      return render json: { status: "error", message: "Invalid parameters" }, status: :bad_request
    end

    config = OauthManagement::OAUTH_PROVIDERS.fetch(provider)
    token_response = Net::HTTP.post_form(
      URI(config[:token_url]),
      {
        grant_type: "authorization_code",
        client_id: config[:client_id],
        redirect_uri: redirect_uri,
        code: code,
        code_verifier: code_verifier
      }
    )
    unless token_response.is_a?(Net::HTTPSuccess)
      return render json: { status: "error", message: "OAuth token request failed" }, status: :unauthorized
    end
    token_data = JSON.parse(token_response.body)

    resources = fetch_resources(token_data["access_token"], provider)
    return if performed?

    # アカウントがあればsession_tokenを返す
    # アカウントが無ければ作成して紐づけてsession_tokenを返す
    uid = resources.dig("data", "persona_aid")
    oauth_account = OauthAccount.find_by(provider: provider, uid: uid)
    account = oauth_account&.account

    if account
      return_new_session(account)
    else
      account = Account.new(
        name: resources.dig("data", "name") || "",
        name_id: resources.dig("data", "name_id") || "",
        description: resources.dig("data", "description") || ""
      )
      account.meta["subscription"] = resources.dig("data", "subscription") || { "status" => "none", "plan" => "basic" }
      if account.save
        OauthAccount.create!(
          account: account,
          provider: provider,
          uid: uid,
          access_token: token_data["access_token"],
          refresh_token: token_data["refresh_token"],
          expires_at: Time.current + token_data["expires_in"].to_i,
          fetched_at: Time.current
        )
        return_new_session(account, { new_account: true })
      else
        render json: { status: "error", message: "アカウントの作成に失敗しました", errors: account.errors.full_messages, new_account: true }, status: :unprocessable_entity
      end
    end
  end

  def signout
    if sign_out
      render json: { status: "success", message: "サインアウトしました" }
    else
      render json: { status: "error", message: "サインアウトできませんでした" }
    end
  end

  private

  def return_new_session(account, info = {})
    db_session = Session.new(account: account)
    access_token = db_session.generate_token(SessionManagement::TOKEN_EXPIRES_IN)

    if db_session.save
      NotificationCreator.call(
        actor: nil,
        recipient: account,
        action: :signin
      )
      res_data = {
        status: "success",
        access_token: access_token,
        expires_in: SessionManagement::TOKEN_EXPIRES_IN.to_i
      }.merge(info)
      render json: res_data
    else
      render json: {
        status: "error",
        message: "トークンを発行できませんでした"
      }.merge(info), status: :unprocessable_entity
    end
  end
end
