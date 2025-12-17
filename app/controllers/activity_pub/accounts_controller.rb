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
      {
        '@context': [
          'https://www.w3.org/ns/activitystreams',
          'https://w3id.org/security/v1'
        ],
        id: account.activity_pub_profile.uri,
        type: 'Person',
        following: account.activity_pub_profile.following_url,
        followers: account.activity_pub_profile.followers_url,
        inbox: account.activity_pub_profile.inbox_url,
        outbox: account.activity_pub_profile.outbox_url,
        sharedInbox: account.activity_pub_profile.shared_inbox_url,
        endpoints: {
          sharedInbox: account.activity_pub_profile.shared_inbox_url
        },
        featured: account.activity_pub_profile.featured_url,
        preferredUsername: account.name_id,
        name: account.name,
        summary: account.description,
        url: account.activity_pub_profile.url,
        manuallyApprovesFollowers: false,
        discoverable: true,
        published: account.created_at.iso8601,
        publicKey: {
          id: "#{account.activity_pub_profile.uri}#main-key",
          owner: account.activity_pub_profile.uri,
          publicKeyPem: account.activity_pub_profile.public_key
        },
        icon: {
          type: 'Image',
          url: account.icon_url
        },
        image: {
          type: 'Image',
          url: account.banner_url
        }
      }
    end
  end
end
