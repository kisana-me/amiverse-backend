class ApplicationMailer < ActionMailer::Base
  default from: "Amiverse <no-reply@amiverse.net>"
  default charset: "UTF-8"
  default headers: { "Content-Language" => "ja" }
  layout "mailer"
end
