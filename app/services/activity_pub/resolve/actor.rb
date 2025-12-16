module ActivityPub
  module Resolve
    class Actor
      # Ex: https://amiverse.net/accounts/12345678901234
      def self.by_uri(uri)
        # DB検索
        profile = ActivityPub::Profile.find_by(uri: uri)
        return profile.account if profile&.account&.normal?

        # URIから取得
        actor_json = fetch_actor_json(uri)
        return nil unless actor_json

        # 保存
        save_data(actor_json)
      end

      # Ex: kisana, amiverse.net
      def self.by_username_domain(username, domain)
        # DB検索
        account = Account.find_by(name_id: "#{username}@#{domain}")
        return account if account&.normal?

        # Web Finger検索
        resource = "acct:#{username}@#{domain}"
        resource_param = URI.encode_www_form_component(resource)
        url = "https://#{domain}/.well-known/webfinger?resource=#{resource_param}"

        response = HttpService.get_request(url)
        return nil unless response.is_a?(Net::HTTPSuccess)

        json = JSON.parse(response.body)
        links = json['links'] || []
        link = links.find { |l| l['type'] == 'application/activity+json' && l['rel'] == 'self' }
        uri = link && link['href'] ? link['href'] : nil
        return nil unless uri

        # URIから取得
        actor_json = fetch_actor_json(uri)
        return nil unless actor_json

        # 保存
        save_data(actor_json)
      rescue => e
        Rails.logger.error "WebFinger failed: #{e.message}"
        nil
      end

      private

      def self.fetch_actor_json(uri)
        headers = { 'Accept' => 'application/activity+json' }
        response = HttpService.get_request(uri, headers)
        return nil unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse actor JSON: #{e.message}"
        nil
      rescue => e
        Rails.logger.error "Failed to fetch actor: #{e.message}"
        nil
      end

      def self.save_data(json)
        # type??
        ActiveRecord::Base.transaction do
          uri = URI.parse(json['id'])
          domain = uri.host

          instance = ActivityPub::Instance.find_or_create_by!(domain: domain)

          username = json['preferredUsername'] || json['id'].split('/').last
          full_username = "#{username}@#{domain}"

          account = Account.find_or_initialize_by(name_id: full_username)
          account.activity_pub_instance = instance
          account.name = json['name'] || username
          account.save!(validate: false)

          profile = account.activity_pub_profile || account.build_activity_pub_profile
          profile.uri = json['id']
          profile.inbox_url = json['inbox']
          profile.outbox_url = json['outbox']
          profile.shared_inbox_url = json['endpoints']&.fetch('sharedInbox', nil)
          profile.followers_url = json['followers']
          profile.following_url = json['following']
          profile.url = json['url']
          profile.actor_type = json['type']
          profile.public_key = json['publicKey']&.fetch('publicKeyPem', nil)

          if json['icon'].is_a?(Hash) && json['icon']['url']
            # profile.icon_url = @json['icon']['url'] # 未完成なのでこのまま
          end
          if json['image'].is_a?(Hash) && json['image']['url']
            # profile.image_url = @json['image']['url'] # 未完成なのでこのまま
          end

          profile.save!
          account
        end
      rescue => e
        Rails.logger.error "Failed to resolve actor: #{e.message}"
        nil
      end
    end
  end
end
