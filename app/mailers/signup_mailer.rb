class SignupMailer < ApplicationMailer
  def verification_code(email, code)
    @code = code
    @expires_in_minutes = SignupCode::EXPIRES_IN.in_minutes.to_i
    mail(to: email, subject: "Amiverse 確認コードのお知らせ")
  end
end
