class V1::SigninController < V1::ApplicationController
  include TurnstileManagement

  rate_limit to: 5, within: 10.minutes,
    with: -> { render json: { status: "error", message: "認証コードの送信が集中しています しばらく待ってからお試しください" }, status: :too_many_requests },
    name: "signin_code_burst",
    only: :code
  rate_limit to: 20, within: 1.day,
    with: -> { render json: { status: "error", message: "認証コードの送信回数が上限に達しました 時間をおいてお試しください" }, status: :too_many_requests },
    name: "signin_code_daily",
    only: :code

  before_action :require_signout

  def code
    email = params[:email].to_s.strip.downcase

    unless email.match?(ApplicationRecord::VALID_EMAIL_REGEX)
      return render json: { status: "error", message: "メールアドレスが不正です" }, status: :unprocessable_entity
    end

    if SigninCode.throttled?(email)
      return render json: { status: "error", message: "認証コードの送信間隔が短すぎます しばらく待ってからお試しください" }, status: :too_many_requests
    end

    unless verify_turnstile(params[:turnstile_token])
      return render json: { status: "error", message: "人間性検証に失敗しました もう一度お試しください" }, status: :unprocessable_entity
    end

    if Account.is_normal.exists?(email: email)
      SigninMailer.verification_code(email, SigninCode.issue(email)).deliver_later
    else
      SigninCode.mark_throttled(email)
    end

    render json: { status: "success", message: "認証コードを送信しました" }, status: :ok
  end

  def create
    email = params[:email].to_s.strip.downcase

    unless SigninCode.verify(email, params[:code])
      return render json: { status: "error", message: "認証コードが正しくないか、有効期限が切れています" }, status: :unprocessable_entity
    end

    account = Account.is_normal.find_by(email: email)

    unless account
      return render json: { status: "error", message: "認証コードが正しくないか、有効期限が切れています" }, status: :unprocessable_entity
    end

    if sign_in(account)
      NotificationCreator.call(
        actor: nil,
        recipient: account,
        action: :signin
      )
      render json: { status: "success", message: "サインインしました" }, status: :ok
    else
      render json: { status: "error", message: "サインインに失敗しました" }, status: :unprocessable_entity
    end
  end
end
