class SigninMailer < ApplicationMailer
  def verification_code(email, code)
    @code = code
    @expires_in_minutes = SigninCode::EXPIRES_IN.in_minutes.to_i
    mail(to: email, subject: "Amiverse 認証コードのお知らせ")
  end
end
