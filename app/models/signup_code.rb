class SignupCode
  # SignupCode Ver. 1.0.0

  EXPIRES_IN = 10.minutes
  RESEND_INTERVAL = 60.seconds
  MAX_ATTEMPTS = 5

  class << self
    def issue(email)
      code = format("%06d", SecureRandom.random_number(1_000_000))
      Rails.cache.write(code_key(email), { digest: digest(code), attempts: 0 }, expires_in: EXPIRES_IN)
      Rails.cache.write(throttle_key(email), true, expires_in: RESEND_INTERVAL)
      code
    end

    def verify(email, code)
      entry = Rails.cache.read(code_key(email))
      return false if entry.blank?

      if entry[:attempts] >= MAX_ATTEMPTS
        discard(email)
        return false
      end

      unless ActiveSupport::SecurityUtils.secure_compare(entry[:digest], digest(code))
        entry[:attempts] += 1
        Rails.cache.write(code_key(email), entry, expires_in: EXPIRES_IN)
        return false
      end

      discard(email)
      true
    end

    def throttled?(email)
      Rails.cache.exist?(throttle_key(email))
    end

    def discard(email)
      Rails.cache.delete(code_key(email))
    end

    private

    def normalize(email)
      email.to_s.strip.downcase
    end

    def code_key(email)
      "signup_code:#{normalize(email)}"
    end

    def throttle_key(email)
      "signup_code_throttle:#{normalize(email)}"
    end

    def digest(code)
      OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, code.to_s)
    end
  end
end
