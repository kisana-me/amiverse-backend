class AccountsController < ApplicationController
  before_action :require_admin

  def show
    username, domain = NormalizeNameIdService.call(params[:name_id])

    if domain.nil?
      # ローカルユーザー
      @account = Account.find_by(name_id: username)
    else
      # リモートユーザー
      remote_name_id = "#{username}@#{domain}"
      @account = Account.find_by(name_id: remote_name_id)

      if @account.nil?
        # WebFingerでURIを引く
        uri = fetch_uri_from_webfinger(username, domain)
        if uri
          # ResolveActorServiceを使って取得・保存
          profile = ActivityPub::ResolveActorService.call(uri)
          @account = profile&.account
        end
      end
    end

    if @account.nil?
      render plain: "Account not found: #{params[:name_id]}", status: 404
    end
  end

  private

  def fetch_uri_from_webfinger(username, domain)
    resource = "acct:#{username}@#{domain}"
    uri = URI("https://#{domain}/.well-known/webfinger?resource=#{resource}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    # タイムアウト設定などを入れるとより安全ですが、簡易実装として省略
    response = http.get(uri.request_uri)
    
    return nil unless response.is_a?(Net::HTTPSuccess)
    
    json = JSON.parse(response.body)
    link = json['links'].find { |l| l['type'] == 'application/activity+json' && l['rel'] == 'self' }
    link ? link['href'] : nil
  rescue => e
    Rails.logger.error "WebFinger failed: #{e.message}"
    nil
  end
end
