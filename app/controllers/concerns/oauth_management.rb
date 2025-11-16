module OauthManagement
  # OAuthManagement Ver. 2.0.0

  OAUTH_PROVIDERS = {
    anyur: {
      client_id: Rails.application.credentials.dig(:oauth_providers, :anyur, :client_id),
      client_secret: Rails.application.credentials.dig(:oauth_providers, :anyur, :client_secret),
      scope: "persona_aid name name_id subscription",
      redirect_url: URI.join(ENV.fetch("APP_URL"), "/oauth/callback").to_s,
      authorize_url: "https://anyur.com/oauth/authorize",
      token_url: "https://anyur.com/oauth/token",
      resource_url: "https://anyur.com/api/resources"
    }
  }.freeze

  require "net/http"

  def generate_authorize_url(state, provider = :anyur)
    raise "Unsupported OAuth provider: #{provider}" unless OAUTH_PROVIDERS.key?(provider)

    config = OAUTH_PROVIDERS.fetch(provider)
    params = {
      response_type: "code",
      client_id: config[:client_id],
      redirect_uri: config[:redirect_url],
      scope: config[:scope],
      state: state
    }
    uri = URI(config[:authorize_url])
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end

  def exchange_code_for_token(code, provider = :anyur)
    raise "Unsupported OAuth provider: #{provider}" unless OAUTH_PROVIDERS.key?(provider)

    config = OAUTH_PROVIDERS.fetch(provider)
    token_response = Net::HTTP.post_form(
      URI(config[:token_url]),
      {
        grant_type: "authorization_code",
        client_id: config[:client_id],
        client_secret: config[:client_secret],
        redirect_uri: config[:redirect_url],
        code: code
      }
    )
    unless token_response.is_a?(Net::HTTPSuccess)
      render plain: "OAuth token request failed: #{token_response.code} #{token_response.body}", status: :unauthorized
      return nil
    end
    JSON.parse(token_response.body)
  end

  def use_refresh_token(refresh_token, provider = :anyur)
    raise "Unsupported OAuth provider: #{provider}" unless OAUTH_PROVIDERS.key?(provider)

    config = OAUTH_PROVIDERS.fetch(provider)
    token_response = Net::HTTP.post_form(
      URI(config[:token_url]),
      {
        grant_type: "refresh_token",
        client_id: config[:client_id],
        client_secret: config[:client_secret],
        refresh_token: refresh_token
      }
    )
    unless token_response.is_a?(Net::HTTPSuccess)
      render plain: "OAuth token refresh failed: #{token_response.code} #{token_response.body}", status: :unauthorized
      return nil
    end
    JSON.parse(token_response.body)
  end

  def fetch_resources(access_token, provider = :anyur)
    raise "Unsupported OAuth provider: #{provider}" unless OAUTH_PROVIDERS.key?(provider)

    config = OAUTH_PROVIDERS.fetch(provider)
    info_uri = URI(config[:resource_url])
    info_request = Net::HTTP::Post.new(info_uri)
    info_request["Authorization"] = "Bearer #{access_token}"
    info_request["Content-Type"] = "application/json"
    info_response = Net::HTTP.start(info_uri.hostname, info_uri.port, use_ssl: info_uri.scheme == "https") do |http|
      http.request(info_request)
    end
    unless info_response.is_a?(Net::HTTPSuccess)
      render plain: "Information request failed: #{info_response.code} #{info_response.body}", status: :unauthorized
      return nil
    end
    JSON.parse(info_response.body)
  end
end
