module TokenTools
  # ver 2.0.0
  # 必要なカラム(名前 型)
  # - ??_lookup string
  # - ??_digest string
  # - ??_generated_at string
  # - ??_expires_at string

  LOOKUP_LENGTH = 36
  BASE36_LENGTH = 128
  extend ActiveSupport::Concern

  def generate_lookup(token, length = LOOKUP_LENGTH)
    Digest::SHA256.hexdigest(token)[0...length]
  end

  def generate_digest(token)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(token, cost: cost)
  end

  def generate_token(expires_in = 0, type = 'token')
    token = SecureRandom.base36(BASE36_LENGTH)
    lookup = generate_lookup(token)
    digest = generate_digest(token)
    send("#{type}_lookup=", lookup)
    send("#{type}_digest=", digest)
    send("#{type}_generated_at=", Time.current)
    send("#{type}_expires_at=", Time.current + expires_in)
    token
  end

  def authenticate_token(token, type = 'token')
    digest = send("#{type}_digest")
    return false unless digest

    BCrypt::Password.new(digest).is_password?(token)
  end

  class_methods do
    def findby_token(token, type = 'token')
      lookup = new.generate_lookup(token)
      record = where("#{type}_expires_at > ?", Time.current)
        .find_by("#{type}_lookup": lookup)
      return nil unless record

      digest = record.send("#{type}_digest")
      return nil unless BCrypt::Password.new(digest).is_password?(token)

      record
    end

    def find_all_by_tokens(tokens, type = 'token')
      return [] if tokens.blank?

      lookups = tokens.map { |token| new.generate_lookup(token) }
      candidates = where("#{type}_expires_at > ?", Time.current)
        .where("#{type}_lookup": lookups)

      tokens.filter_map do |token|
        candidates.find do |record|
          BCrypt::Password.new(record.send("#{type}_digest")).is_password?(token)
        end
      end.uniq
    end
  end
end
