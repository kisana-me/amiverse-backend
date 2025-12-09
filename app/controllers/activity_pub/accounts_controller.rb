module ActivityPub
  class AccountsController < ApplicationController
    def show
      @account = Account
        .is_normal
        .is_opened
        .find_by(aid: params[:aid])

      if @account.nil? || @account.remote? || @account.activity_pub_profile.nil?
        render json: { error: 'Not Found' }, status: :not_found
        return
      end

      render json: serialize_account(@account), content_type: 'application/activity+json'
    end

    private

    def serialize_account(account)
      front_uri = URI.parse(ENV.fetch('FRONT_URL'))
      host_options = { host: front_uri.host, protocol: front_uri.scheme }
      host_options[:port] = front_uri.port unless [80, 443].include?(front_uri.port)

      {
        '@context': [
          'https://www.w3.org/ns/activitystreams',
          'https://w3id.org/security/v1'
        ],
        id: account_url(account.aid, host_options),
        type: 'Person',
        following: following_account_url(account.aid, host_options),
        followers: followers_account_url(account.aid, host_options),
        inbox: inbox_account_url(account.aid, host_options),
        outbox: outbox_account_url(account.aid, host_options),
        featured: collections_featured_account_url(account.aid, host_options),
        preferredUsername: account.name_id,
        name: account.name,
        summary: account.description,
        url: "https://#{front_uri.host}/@#{account.name_id}",
        manuallyApprovesFollowers: false,
        discoverable: true,
        published: account.created_at.iso8601,
        publicKey: {
          id: "#{account_url(account.aid, host_options)}#main-key",
          owner: account_url(account.aid, host_options),
          publicKeyPem: account.activity_pub_profile.public_key
        },
        icon:
          if account.icon.present?
            {
              type: 'Image',
              mediaType: 'image/webp',
              url: account.icon_url
            }
          else
            nil
          end,
        image:
          if account.banner.present?
            {
              type: 'Image',
              mediaType: 'image/webp',
              url: account.banner_url
            }
          else
            nil
          end
      }
    end
  end
end
