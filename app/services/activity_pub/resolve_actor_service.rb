require 'net/http'
require 'uri'

module ActivityPub
  class ResolveActorService
    def self.call(uri)
      new(uri).call
    end

    def initialize(uri)
      @uri = uri
    end

    def call
      # 1. DB検索
      profile = ActivityPub::Profile.find_by(uri: @uri)
      return profile if profile

      # 2. リモートから取得
      actor_json = fetch_actor_json
      return nil unless actor_json

      # 3. 保存
      save_actor(actor_json)
    end

    private

    def fetch_actor_json
      uri = URI.parse(@uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      
      request = Net::HTTP::Get.new(uri)
      request['Accept'] = 'application/activity+json'
      
      response = http.request(request)
      
      return nil unless response.is_a?(Net::HTTPSuccess)
      
      JSON.parse(response.body)
    rescue => e
      Rails.logger.error "Failed to fetch actor: #{e.message}"
      nil
    end

    def save_actor(json)
      ActiveRecord::Base.transaction do
        # ドメインの取得
        uri = URI.parse(json['id'])
        domain = uri.host

        # インスタンスの取得または作成
        instance = ActivityPub::Instance.find_or_create_by!(domain: domain)

        # ユーザー名の決定 (preferredUsername がなければIDから生成)
        username = json['preferredUsername'] || json['id'].split('/').last
        full_username = "#{username}@#{domain}"
        
        # アカウントの作成
        account = Account.find_or_initialize_by(name_id: full_username)
        account.activity_pub_instance = instance
        account.name = json['name'] || username
        
        # リモートユーザーはパスワード等のバリデーションをスキップして保存
        account.save!(validate: false)

        # プロフィールの作成
        profile = account.build_activity_pub_profile
        profile.uri = json['id']
        profile.inbox_url = json['inbox']
        profile.outbox_url = json['outbox']
        profile.shared_inbox_url = json['endpoints']&.fetch('sharedInbox', nil)
        profile.followers_url = json['followers']
        profile.following_url = json['following']
        profile.url = json['url']
        profile.actor_type = json['type']
        profile.public_key = json['publicKey']&.fetch('publicKeyPem', nil)
        
        # アイコン・ヘッダー画像
        if json['icon'].is_a?(Hash) && json['icon']['url']
          profile.icon_url = json['icon']['url']
        end
        if json['image'].is_a?(Hash) && json['image']['url']
          profile.image_url = json['image']['url']
        end

        profile.save!
        profile
      end
    rescue => e
      Rails.logger.error "Failed to save actor: #{e.message}"
      nil
    end
  end
end
