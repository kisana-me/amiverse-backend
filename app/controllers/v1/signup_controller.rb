class V1::SignupController < V1::ApplicationController
  include TurnstileManagement

  rate_limit to: 5, within: 10.minutes,
    with: -> { render json: { status: "error", message: "確認コードの送信が集中しています しばらく待ってからお試しください" }, status: :too_many_requests },
    name: "signup_code_burst",
    only: :code
  rate_limit to: 20, within: 1.day,
    with: -> { render json: { status: "error", message: "確認コードの送信回数が上限に達しました 時間をおいてお試しください" }, status: :too_many_requests },
    name: "signup_code_daily",
    only: :code

  before_action :require_signout
  before_action :ensure_oauth_context, only: %i[oauth]

  def code
    email = params[:email].to_s.strip.downcase

    unless email.match?(ApplicationRecord::VALID_EMAIL_REGEX)
      return render json: { status: "error", message: "メールアドレスが不正です" }, status: :unprocessable_entity
    end

    if SignupCode.throttled?(email)
      return render json: { status: "error", message: "確認コードの送信間隔が短すぎます しばらく待ってからお試しください" }, status: :too_many_requests
    end

    unless verify_turnstile(params[:turnstile_token])
      return render json: { status: "error", message: "人間性検証に失敗しました もう一度お試しください" }, status: :unprocessable_entity
    end

    if Account.exists?(email: email)
      SignupCode.mark_throttled(email)
    else
      SignupMailer.verification_code(email, SignupCode.issue(email)).deliver_later
    end

    render json: { status: "success", message: "確認コードを送信しました" }, status: :ok
  end

  def create
    email = account_params[:email].to_s.strip.downcase

    unless ActiveModel::Type::Boolean.new.cast(account_params[:is_agreed])
      return render json: { status: "error", message: "利用規約とプライバシーポリシーへの同意が必要です" }, status: :unprocessable_entity
    end

    @account = Account.new(account_params.except(:is_agreed))
    @account.email = email
    @account.email_verified = true
    @account.agreed_at = Time.current

    # メール重複エラーは列挙につながるため、それ以外の検証エラーのみ先に返す
    # （登録済みメールには確認コードを発行していないので、下の verify で弾かれる）
    @account.valid?
    other_errors = @account.errors.reject { |err| err.attribute == :email && err.type == :taken }
    if other_errors.present?
      return render json: { status: "error", message: "登録に失敗しました", errors: other_errors.map(&:full_message) }, status: :unprocessable_entity
    end

    unless SignupCode.verify(email, params[:code])
      return render json: { status: "error", message: "確認コードが正しくないか、有効期限が切れています" }, status: :unprocessable_entity
    end

    if @account.save
      sign_in(@account)
      NotificationCreator.call(
        actor: nil,
        recipient: @account,
        action: :signin
      )
      render json: { status: "success", message: "登録が完了しました" }, status: :created
    else
      render json: { status: "error", message: "登録に失敗しました", errors: @account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def oauth
    @account = Account.new(oauth_account_params)
    @account.meta["subscription"] = session[:oauth_signup]["subscription"]

    if @account.save
      sign_in(@account)
      NotificationCreator.call(
        actor: nil,
        recipient: @account,
        action: :signin
      )
      OauthAccount.create!(
        account: @account,
        provider: session[:oauth_signup]["provider"],
        uid: session[:oauth_signup]["uid"],
        access_token: session[:oauth_signup]["access_token"],
        refresh_token: session[:oauth_signup]["refresh_token"],
        expires_at: session[:oauth_signup]["expires_at"],
        fetched_at: session[:oauth_signup]["fetched_at"]
      )
      session.delete(:oauth_signup)
      render json: { status: "success", message: "登録が完了しました" }, status: :created
    else
      render json: { status: "error", message: "登録に失敗しました", errors: @account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def ensure_oauth_context
    unless session[:oauth_signup].present?

      render json: { status: "error", message: "不正なアクセスです" }, status: :forbidden
    end
  end

  def account_params
    params.expect(
      account: %i[
        name
        name_id
        email
        is_agreed
      ]
    )
  end

  def oauth_account_params
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
