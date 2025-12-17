module ActivityPub
  class FollowersController < ApplicationController
    def index
      @account = Account
        .is_normal
        .is_opened
        .find_by(aid: params[:aid])

      if @account.nil? || @account.remote? || @account.activity_pub_profile.nil?
        render json: { error: 'Not Found' }, status: :not_found
        return
      end

      render json: serialize_followers(@account), content_type: 'application/activity+json'
    end

    private

    def serialize_followers(account)
      id = account.activity_pub_profile.followers_url

      if params[:page] == 'true'
        {
          '@context': 'https://www.w3.org/ns/activitystreams',
          id: "#{id}?page=true",
          type: 'OrderedCollectionPage',
          partOf: id,
          orderedItems: [] # TODO: Implement followers serialization
        }
      else
        {
          '@context': 'https://www.w3.org/ns/activitystreams',
          id: id,
          type: 'OrderedCollection',
          totalItems: account.followers.count,
          first: "#{id}?page=true"
        }
      end
    end
  end
end
