require "net/http"

module TurnstileManagement
  # TurnstileManagement Ver. 1.1.0
  # ENV: CLOUDFLARE_TURNSTILE_SECRET_KEY

  SITEVERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify".freeze
  TIMEOUT = 5

  private

  def verify_turnstile(token)
    secret = ENV["CLOUDFLARE_TURNSTILE_SECRET_KEY"]
    return false if secret.blank?
    return false if token.blank?

    uri = URI(SITEVERIFY_URL)
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
      http.post(uri.path, URI.encode_www_form(
        secret: secret,
        response: token,
        remoteip: request.remote_ip
      ))
    end

    result = JSON.parse(res.body)
    return true if result["success"]

    Rails.logger.info("Turnstile verification failed: #{result["error-codes"]}")
    false
  rescue StandardError => e
    Rails.logger.error("Turnstile verification error: #{e.class}: #{e.message}")
    false
  end
end
