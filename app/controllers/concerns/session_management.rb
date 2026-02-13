module SessionManagement
  # SessionManagement Ver. 2.0.2
  # models/token_toolsが必須
  # Sessionに必要なカラム差分(名前 型)
  # - account references
  # Accountに必要なカラム(名前 型)
  # - status enum { normal: 0, locked: 1, deleted: 2 }

  COOKIE_NAME = 'amiverse'.freeze
  COOKIE_EXPIRES_IN = 6.months
  TOKEN_EXPIRES_IN = 6.months

  def current_account
    @current_account = nil
    tokens = get_tokens
    cookie_needs_update = false

    while tokens.any?
      token = tokens.first
      db_session = Session.isnt_deleted.from_not_deleted_account.findby_token(token)
      if db_session
        @current_account = db_session.account
        break
      else
        tokens.shift
        cookie_needs_update = true
      end
    end

    write_tokens(tokens) if cookie_needs_update
    @current_account
  end

  def sign_in(account)
    return false if account.nil? || account.deleted?

    db_session = Session.new(account: account)
    token = db_session.generate_token(TOKEN_EXPIRES_IN)

    if db_session.save
      tokens = get_tokens
      tokens.unshift(token)
      write_tokens(tokens.uniq)
      true
    else
      false
    end
  end

  def sign_out
    tokens = get_tokens
    return false unless (token = tokens.shift)

    db_session = Session.isnt_deleted.from_not_deleted_account.findby_token(token)
    db_session&.update(status: :deleted)

    if tokens.empty?
      cookies.delete(COOKIE_NAME.to_sym)
    else
      write_tokens(tokens)
    end
    @current_account = nil
    true
  end

  def signed_in_accounts
    db_sessions = Session
      .isnt_deleted
      .from_not_deleted_account
      .includes(:account)
      .find_all_by_tokens(get_tokens)
    db_sessions.map(&:account).uniq
  end

  def change_account(account_aid)
    tokens = get_tokens
    target_token = nil
    tokens.shift

    while tokens.any?
      token = tokens.first
      db_session = Session.isnt_deleted.from_not_deleted_account.findby_token(token)
      if db_session && db_session.account.aid == account_aid
        target_token = token
        break
      else
        tokens.shift
      end
    end
    return false unless target_token

    new_tokens = get_tokens.partition { |t| t == target_token }.flatten
    write_tokens(new_tokens)
    true
  end

  private

  def get_tokens
    cookie_raw = cookies.encrypted[COOKIE_NAME.to_sym]
    if cookie_raw.present?
      JSON.parse(cookie_raw)
    else
      auth = authorization_header_value
      return [] if auth.blank?

      token = auth.sub(/\ABearer\s+/i, '')
      token.present? ? [token] : []
    end
  rescue JSON::ParserError
    []
  end

  def write_tokens(tokens)
    cookies.encrypted[COOKIE_NAME.to_sym] = {
      value: tokens.to_json,
      domain: :all,
      tld_length: 2,
      same_site: :lax,
      expires: Time.current + COOKIE_EXPIRES_IN,
      secure: Rails.env.production?,
      httponly: true
    }
  end

  def authorization_header_value
    return nil unless respond_to?(:request) && request

    request.headers['Authorization'].presence
  end
end
