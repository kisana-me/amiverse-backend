module ActivityPub
  class CollectionsController < ApplicationController
    def featured
      @account = Account
        .is_normal
        .is_opened
        .find_by(aid: params[:aid])

      if @account.nil? || @account.remote? || @account.activity_pub_profile.nil?
        render json: { error: 'Not Found' }, status: :not_found
        return
      end

      render json: serialize_featured(@account), content_type: 'application/activity+json'
    end

    private

    def serialize_featured(account)
      id = account.activity_pub_profile.featured_url

      {
        '@context': 'https://www.w3.org/ns/activitystreams',
        id: id,
        type: 'OrderedCollection',
        totalItems: 0,
        orderedItems: []
      }
    end
  end
end
