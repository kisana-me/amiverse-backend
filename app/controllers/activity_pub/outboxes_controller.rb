module ActivityPub
  class OutboxesController < ApplicationController
    def show
      @account = Account
        .is_normal
        .is_opened
        .find_by(aid: params[:aid])

      if @account.nil? || @account.remote? || @account.activity_pub_profile.nil?
        render json: { error: 'Not Found' }, status: :not_found
        return
      end

      render json: serialize_outbox(@account), content_type: 'application/activity+json'
    end

    private

    def serialize_outbox(account)
      id = account.activity_pub_profile.outbox_url

      if params[:page] == 'true'
        {
          '@context': 'https://www.w3.org/ns/activitystreams',
          id: "#{id}?page=true",
          type: 'OrderedCollectionPage',
          partOf: id,
          orderedItems: [] # TODO: Implement activity serialization
        }
      else
        {
          '@context': 'https://www.w3.org/ns/activitystreams',
          id: id,
          type: 'OrderedCollection',
          totalItems: account.posts.is_normal.isnt_deleted.count,
          first: "#{id}?page=true",
          last: "#{id}?page=true&min_id=0"
        }
      end
    end
  end
end
